import { Request, Response, NextFunction } from 'express';
import { authService } from '../services/auth.service';
import { AppError } from '../utils/AppError';
import logger from '../utils/logger';

export interface AuthRequest extends Request {
  user?: {
    userId: string;
    role: string;
  };
  csrfToken?: string;
  file?: Express.Multer.File;
}

/**
 * Verify JWT access token from Authorization header
 */
export const authMiddleware = (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): void => {
  const token = req.headers.authorization?.split(' ')[1];

  if (!token) {
    return next(new AppError('Authorization token is missing', 401));
  }

  try {
    const payload = authService.verifyToken(token, 'access');
    req.user = {
      userId: payload.userId,
      role: payload.role,
    };
    res.locals.userId = payload.userId;
    next();
  } catch (error) {
    if (error instanceof AppError) {
      next(error);
    } else {
      logger.error('Auth middleware error:', error);
      next(new AppError('Invalid or expired token', 401));
    }
  }
};

/**
 * Verify user has specific role
 */
export const roleMiddleware = (allowedRoles: string[]) => {
  return (req: AuthRequest, res: Response, next: NextFunction): void => {
    if (!req.user) {
      return next(new AppError('User not authenticated', 401));
    }

    if (!allowedRoles.includes(req.user.role)) {
      return next(new AppError('You do not have permission to access this resource', 403));
    }

    next();
  };
};
