import { Request, Response, NextFunction } from 'express';
import securityService from '../services/security.service';

interface RateLimitOptions {
  windowMinutes?: number;
  maxRequests?: number;
  keyGenerator?: (req: Request) => string;
  skipSuccessfulRequests?: boolean;
  skipFailedRequests?: boolean;
}

/**
 * Generic rate limiting middleware
 */
export const createRateLimiter = (options: RateLimitOptions & { windowMs?: number; max?: number } = {}) => {
  const windowMs = options.windowMs || (options.windowMinutes ? options.windowMinutes * 60 * 1000 : 15 * 60 * 1000);
  const max = options.max || options.maxRequests || 10;
  const keyGenerator = options.keyGenerator || ((req) => req.ip || 'unknown');

  return async (req: Request, res: Response, next: NextFunction) => {
    if (process.env.NODE_ENV === 'test' && !req.headers['x-test-rate-limit']) {
      return next();
    }
    try {
      const identifier = keyGenerator(req);
      const windowMinutes = windowMs / (60 * 1000);
      const { allowed, remaining, resetAt } = await securityService.checkRateLimit(
        identifier,
        max,
        windowMinutes
      );

      // Set rate limit headers
      const headers: Record<string, any> = {
        'X-RateLimit-Limit': max,
        'X-RateLimit-Remaining': remaining,
        'X-RateLimit-Reset': resetAt.getTime(),
      };

      if (!allowed) {
        const retryAfter = Math.ceil((resetAt.getTime() - Date.now()) / 1000);
        headers['Retry-After'] = retryAfter;
      }

      if (typeof res.set === 'function') {
        res.set(headers);
      } else {
        for (const [key, val] of Object.entries(headers)) {
          res.setHeader(key, String(val));
        }
      }

      if (!allowed) {
        return res.status(429).json({
          status: 'fail',
          message: `Rate limit exceeded. Try again after ${Math.ceil(
            (resetAt.getTime() - Date.now()) / 1000
          )} seconds`,
        });
      }

      next();
    } catch (error) {
      return res.status(500).json({
        status: 'error',
        message: error instanceof Error ? error.message : 'Internal Server Error',
      });
    }
  };
};

/**
 * Auth endpoint rate limiter
 * More strict for login/signup endpoints (5 attempts per 15 min)
 */
export const authRateLimiter = createRateLimiter({
  windowMinutes: 15,
  maxRequests: 5,
  keyGenerator: (req) => {
    // Rate limit by IP + email (if provided)
    const email = req.body?.email;
    return email ? `${req.ip}_${email}` : (req.ip || 'unknown');
  },
});

/**
 * API rate limiter
 * General API endpoint limiter (100 requests per 15 min)
 */
export const apiRateLimiter = createRateLimiter({
  windowMinutes: 15,
  maxRequests: 100,
  keyGenerator: (req) => req.ip || 'unknown',
});

/**
 * Strict rate limiter for sensitive operations
 * Only 3 attempts per 30 minutes
 */
export const sensitiveOpRateLimiter = createRateLimiter({
  windowMinutes: 30,
  maxRequests: 3,
  keyGenerator: (req) => {
    const userId = (req as any).user?.userId;
    return userId || req.ip || 'unknown';
  },
});

/**
 * Custom rate limiter with endpoint-specific limits
 */
export const createEndpointRateLimiter = (endpoint: string, maxRequests: number, windowMinutes: number = 15) => {
  return createRateLimiter({
    windowMinutes,
    maxRequests,
    keyGenerator: (req) => `${endpoint}_${req.ip || 'unknown'}`,
  });
};


