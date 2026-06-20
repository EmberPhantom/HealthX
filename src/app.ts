import express, { Express, Request, Response, NextFunction } from 'express';
import helmet from 'helmet';
import cors from 'cors';
import morgan from 'morgan';
import path from 'path';
import mongoSanitize from 'express-mongo-sanitize';
import * as Sentry from '@sentry/node';
import { config } from './config/config';
import { securityConfig } from './config/security.config';
import logger from './utils/logger';
import { errorMiddleware } from './middlewares/errorMiddleware';
import { authMiddleware } from './middlewares/auth.middleware';
import { AppError } from './utils/AppError';
import routes from './routes';
import swaggerUi from 'swagger-ui-express';
import { swaggerSpec } from './docs/swagger';
import { isRedisConnected } from './config/redis';
import mongoose from 'mongoose';

const app: Express = express();

// Initialize Sentry before other middlewares
if (config.sentry.dsn) {
  Sentry.init({
    dsn: config.sentry.dsn,
    environment: config.env,
    tracesSampleRate: 1.0,
  });
}

// Security middleware
const cspDirectives = { ...securityConfig.csp.directives };
if (config.env !== 'production') {
  cspDirectives.scriptSrc = [...cspDirectives.scriptSrc, "'unsafe-inline'"];
  cspDirectives.styleSrc = [...cspDirectives.styleSrc, "'unsafe-inline'"];
}
app.use(helmet({
  contentSecurityPolicy: {
    directives: cspDirectives,
  },
  hsts: {
    maxAge: securityConfig.https.hstsMaxAge,
    includeSubDomains: securityConfig.https.hstsIncludeSubdomains,
    preload: securityConfig.https.hstsPreload,
  },
}));
app.use(
  cors({
    origin: (origin, callback) => {
      if (config.env === 'production') {
        // Strict production CORS lockdown
        if (!origin || securityConfig.cors.origins.includes(origin)) {
          callback(null, true);
        } else {
          callback(new AppError('Not allowed by CORS', 403));
        }
      } else {
        // Permissive development CORS rules
        const allowedOrigins = [
          config.frontend.url,
          'http://localhost:8080',
          'http://localhost:3000'
        ];
        if (!origin || allowedOrigins.includes(origin) || config.env === 'development') {
          callback(null, true);
        } else {
          callback(new AppError('Not allowed by CORS', 403));
        }
      }
    },
    credentials: true,
  })
);

// Logging middleware
if (config.env === 'development') {
  app.use(morgan('dev'));
} else {
  app.use(morgan('combined'));
}

// Body parser middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));

// Prevent NoSQL query injection
app.use(mongoSanitize());

// Static file serving for uploads (protected for /documents)
app.use('/uploads', (req: Request, res: Response, next: NextFunction) => {
  if (req.path.startsWith('/documents')) {
    return authMiddleware(req as any, res, next);
  }
  next();
}, express.static(path.join(process.cwd(), 'uploads')));

// Serve assets statically for seeded records
app.use('/assets', express.static(path.join(process.cwd(), 'frontend', 'assets')));

// NOTE: CSRF protection middleware (`csrf.middleware.ts`) is fully implemented but is
// intentionally not mounted globally because the primary client is a Flutter mobile app
// (`frontend_v2`). Mobile applications utilize header-based authentication (Bearer JWT)
// rather than session cookies, making them inherently immune to standard browser-based CSRF.
// If a web frontend/dashboard is introduced, CSRF protection should be enabled on those routes.

// Health check endpoint
app.get('/health', async (req: Request, res: Response) => {
  const dbState = mongoose.connection.readyState;
  const dbStatus = dbState === 1 ? 'connected' : 'disconnected';
  const redisStatus = isRedisConnected() ? 'connected' : 'degraded (in-memory fallback)';
  const isHealthy = dbState === 1;

  res.status(isHealthy ? 200 : 503).json({
    status: isHealthy ? 'healthy' : 'degraded',
    timestamp: new Date().toISOString(),
    environment: config.env,
    version: process.env.npm_package_version || '1.0.0',
    services: {
      database: dbStatus,
      cache: redisStatus,
    },
    uptime: process.uptime(),
  });
});

// Root route - serve the landing page
app.get('/', (req: Request, res: Response) => {
  res.sendFile(path.join(__dirname, 'views', 'index.html'));
});

// API v1 routes
app.use('/api/v1', routes);

// Swagger API Docs
if (config.env !== 'production') {
  app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));
  app.get('/api-docs.json', (req: Request, res: Response) => res.json(swaggerSpec));
}

// 404 handler
app.use((req: Request, res: Response, next: NextFunction) => {
  throw new AppError(`Route ${req.originalUrl} not found`, 404);
});

// Sentry error handler (must be registered before other error middlewares)
if (config.sentry.dsn) {
  Sentry.setupExpressErrorHandler(app);
}

// Global error handler middleware
app.use(errorMiddleware);

export default app;