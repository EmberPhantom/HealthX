import { Request, Response, NextFunction } from 'express';
import securityService from '../services/security.service';

interface AuditRequest extends Request {
  auditAction?: string;
  auditDetails?: Record<string, any>;
}

/**
 * Audit logging middleware
 * Logs security-relevant actions (auth, profile changes, etc.)
 */
export const auditLog = (action: 'LOGIN' | 'LOGOUT' | 'SIGNUP' | 'PASSWORD_CHANGE' | 'PROFILE_UPDATE' | 'OAUTH_LOGIN' | 'FAILED_LOGIN' | 'ACCOUNT_LOCKED') => {
  return async (req: AuditRequest, res: Response, next: NextFunction) => {
    try {
      // Store action for later logging
      req.auditAction = action;

      // Intercept response to log result
      const originalSend = res.send;
      res.send = function (data) {
        // Log the audit event
        const userId = (req as any).user?.userId || null;
        const ipAddress = req.ip || 'unknown';
        const userAgent = req.headers['user-agent'];
        const success = res.statusCode < 400;

        securityService.logSecurityEvent(
          userId,
          action,
          req.path.split('/')[1] || 'api',
          req.method as any,
          req.path,
          res.statusCode,
          ipAddress,
          userAgent,
          req.auditDetails || { body: req.body },
          success
        ).catch((err) => console.error('Error logging audit event:', err));

        return originalSend.call(this, data);
      };

      next();
    } catch (error) {
      next(error);
    }
  };
};

/**
 * Track login attempts
 * Middleware to track login success/failure
 */
export const trackLoginAttempt = async (
  req: AuditRequest,
  res: Response,
  next: NextFunction
) => {
  try {
    const email = req.body?.email;
    if (!email) {
      return next();
    }

    const ipAddress = req.ip || 'unknown';
    const userAgent = req.headers['user-agent'];

    // Intercept response
    const originalSend = res.send;
    res.send = function (data) {
      const success = res.statusCode === 200;
      const userId = res.locals?.userId || null;

      securityService.trackLoginAttempt(
        email,
        ipAddress,
        success,
        userAgent,
        userId
      ).catch((err) => console.error('Error tracking login attempt:', err));

      return originalSend.call(this, data);
    };

    next();
  } catch (error) {
    next(error);
  }
};

/**
 * Check for suspicious activity
 * Blocks requests from IPs with too many failed attempts
 */
export const checkSuspiciousActivity = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const ipAddress = req.ip || 'unknown';

    // Skip for whitelisted IPs
    if (isWhitelistedIP(ipAddress)) {
      return next();
    }

    const activity = await securityService.getSuspiciousActivity(ipAddress);

    if (activity.isBlocked) {
      const secondsUntilUnlock = activity.blockDetails
        ? Math.ceil((activity.blockDetails.blockedUntil.getTime() - Date.now()) / 1000)
        : 0;

      return res.status(429).json({
        success: false,
        message: `Your IP has been temporarily blocked due to suspicious activity. Try again in ${secondsUntilUnlock} seconds.`,
        code: 'IP_BLOCKED',
        unblockTime: activity.blockDetails?.blockedUntil,
      });
    }

    // Warn if high failed attempt count
    if (activity.failedAttempts > 3) {
      res.setHeader('X-Security-Warning', `${activity.failedAttempts} failed login attempts detected`);
    }

    next();
  } catch (error) {
    // Fail open on error
    next();
  }
};

/**
 * IP whitelist for security checks
 */
function isWhitelistedIP(ip: string): boolean {
  const whitelist = process.env.IP_WHITELIST?.split(',') || [
    '127.0.0.1',
    '::1',
    'localhost',
  ];
  return whitelist.includes(ip);
}

/**
 * Log security headers
 * Logs all requests with security headers
 */
export const logSecurityHeaders = (req: Request, res: Response, next: NextFunction) => {
  try {
    const securityHeaders = {
      'x-csrf-token': req.headers['x-csrf-token'],
      'x-requested-with': req.headers['x-requested-with'],
      'x-forwarded-for': req.headers['x-forwarded-for'],
      'user-agent': req.headers['user-agent'],
    };

    // Log suspicious headers patterns
    if (
      !securityHeaders['x-csrf-token'] &&
      ['POST', 'PUT', 'DELETE', 'PATCH'].includes(req.method) &&
      !isPublicEndpoint(req.path)
    ) {
      console.warn(
        `[Security] Missing CSRF token for ${req.method} ${req.path} from ${req.ip}`
      );
    }

    next();
  } catch (error) {
    next(error);
  }
};

/**
 * Check if endpoint is public
 */
function isPublicEndpoint(path: string): boolean {
  const publicPaths = [
    '/health',
    '/api/v1/auth/signup',
    '/api/v1/auth/login',
    '/api/v1/auth/google',
    '/api/v1/onboarding/verify-email',
  ];
  return publicPaths.some((p) => path.startsWith(p));
}
