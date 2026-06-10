import { Response } from 'express';
import securityService from '../services/security.service';
import AuditLog from '../models/AuditLog';
import { AppError } from '../utils/AppError';
import { catchAsync } from '../utils/catchAsync';
import { AuthRequest } from '../middlewares/auth.middleware';

/**
 * GET /security/csrf-token
 * Get CSRF token for client
 */
export const getCSRFToken = catchAsync(async (req: AuthRequest, res: Response) => {
  const csrfToken = req.csrfToken ? req.csrfToken : 'N/A';

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    message: 'CSRF token retrieved',
    data: {
      csrfToken,
    },
  });
});

/**
 * GET /security/login-history
 * Get user's login history
 */
export const getLoginHistory = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const history = await securityService.getLoginHistory(req.user.userId, 10);

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    message: 'Login history retrieved',
    data: {
      total: history.length,
      logins: history.map((entry) => ({
        id: entry._id,
        email: (entry as any).email,
        action: entry.action,
        ipAddress: entry.ipAddress,
        userAgent: entry.userAgent,
        success: entry.success,
        attemptedAt: (entry as any).attemptedAt || entry.timestamp,
      })),
    },
  });
});

/**
 * GET /security/suspicious-activity
 * Get suspicious activity (admin only)
 */
export const getSuspiciousActivity = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user || req.user.role !== 'admin') {
    throw new AppError('Only admins can view suspicious activity', 403);
  }

  const ipAddress = req.query.ip as string;

  if (!ipAddress) {
    throw new AppError('IP address is required', 400);
  }

  const activity = await securityService.getSuspiciousActivity(ipAddress);

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    message: 'Suspicious activity retrieved',
    data: {
      ipAddress,
      ...activity,
    },
  });
});

/**
 * POST /security/clear-failed-attempts
 * Clear failed login attempts for an email (admin only)
 */
export const clearFailedAttempts = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user || req.user.role !== 'admin') {
    throw new AppError('Only admins can clear failed attempts', 403);
  }

  const { email } = req.body;

  if (!email) {
    throw new AppError('Email is required', 400);
  }

  await securityService.clearFailedAttempts(email);

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    message: 'Failed attempts cleared',
    data: {
      email,
    },
  });
});

/**
 * GET /security/audit-logs
 * Get audit logs (admin only)
 */
export const getAuditLogs = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user || req.user.role !== 'admin') {
    throw new AppError('Only admins can view audit logs', 403);
  }

  const page = parseInt(req.query.page as string) || 1;
  const limit = Math.min(parseInt(req.query.limit as string) || 50, 200);
  const skip = (page - 1) * limit;
  const action = req.query.action as string;
  const userId = req.query.userId as string;
  const from = req.query.from ? new Date(req.query.from as string) : undefined;
  const to = req.query.to ? new Date(req.query.to as string) : undefined;

  const filter: any = {};
  if (action) filter.action = action;
  if (userId) filter.userId = userId;
  if (from || to) {
    filter.timestamp = {};
    if (from) filter.timestamp.$gte = from;
    if (to) filter.timestamp.$lte = to;
  }

  const [logs, total] = await Promise.all([
    AuditLog.find(filter)
      .sort({ timestamp: -1 })
      .skip(skip)
      .limit(limit)
      .lean(),
    AuditLog.countDocuments(filter),
  ]);

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    message: 'Audit logs retrieved successfully',
    data: { total, page, limit, totalPages: Math.ceil(total / limit), logs },
  });
});
