import express, { Express, Request, Response, NextFunction } from 'express';
import helmet from 'helmet';
import cors from 'cors';
import morgan from 'morgan';
import path from 'path';
import mongoSanitize from 'express-mongo-sanitize';
import passport from './config/passport';
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

// Security middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: securityConfig.csp.directives.defaultSrc,
      scriptSrc: securityConfig.csp.directives.scriptSrc,
      styleSrc: securityConfig.csp.directives.styleSrc,
      imgSrc: securityConfig.csp.directives.imgSrc,
      connectSrc: securityConfig.csp.directives.connectSrc,
      fontSrc: securityConfig.csp.directives.fontSrc,
      objectSrc: securityConfig.csp.directives.objectSrc,
      mediaSrc: securityConfig.csp.directives.mediaSrc,
      frameSrc: securityConfig.csp.directives.frameSrc,
    },
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
      // Allow local development origins and physical devices
      const allowedOrigins = [
        config.frontend.url,
        'http://localhost:8080',
        'http://localhost:3000'
      ];
      if (!origin || allowedOrigins.indexOf(origin) !== -1 || config.env === 'development') {
        callback(null, true);
      } else {
        callback(new Error('Not allowed by CORS'));
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

// Initialize Passport
app.use(passport.initialize());

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

// Global error handler middleware
app.use(errorMiddleware);

export default app;