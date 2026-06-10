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
  try {
    const token = req.headers.authorization?.split(' ')[1];

    if (!token) {
      throw new AppError('Authorization token is missing', 401);
    }

    try {
      const payload = authService.verifyToken(token, 'access');
      req.user = {
        userId: payload.userId,
        role: payload.role,
      };
      next();
    } catch (error) {
      if (error instanceof AppError) throw error;
      throw new AppError('Invalid or expired token', 401);
    }
  } catch (error) {
    if (error instanceof AppError) {
      res.status(error.statusCode).json({
        statusCode: error.statusCode,
        status: 'fail',
        message: error.message,
      });
    } else {
      logger.error('Auth middleware error:', error);
      res.status(500).json({
        statusCode: 500,
        status: 'error',
        message: 'Authentication failed',
      });
    }
  }
};

/**
 * Verify user has specific role
 */
export const roleMiddleware = (allowedRoles: string[]) => {
  return (req: AuthRequest, res: Response, next: NextFunction): void => {
    if (!req.user) {
      res.status(401).json({
        statusCode: 401,
        status: 'fail',
        message: 'User not authenticated',
      });
      return;
    }

    if (!allowedRoles.includes(req.user.role)) {
      res.status(403).json({
        statusCode: 403,
        status: 'fail',
        message: 'You do not have permission to access this resource',
      });
      return;
    }

    next();
  };
};
