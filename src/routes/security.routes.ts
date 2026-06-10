import express, { Router } from 'express';
import * as securityController from '../controllers/security.controller';
import { authMiddleware, roleMiddleware } from '../middlewares/auth.middleware';
import { generateCSRFToken } from '../middlewares/csrf.middleware';
import { validateRequest } from '../middlewares/validate.middleware';
import { z } from 'zod';

const router: Router = express.Router();

// Schema for clear failed attempts
const clearFailedAttemptsSchema = z.object({
  email: z.string().email('Invalid email address'),
});

/**
 * GET /security/csrf-token
 * Get CSRF token (public)
 */
router.get(
  '/csrf-token',
  generateCSRFToken as any,
  securityController.getCSRFToken as any
);

/**
 * GET /security/login-history
 * Get login history (authenticated)
 */
router.get(
  '/login-history',
  authMiddleware as any,
  securityController.getLoginHistory as any
);

/**
 * GET /security/suspicious-activity
 * Get suspicious activity for IP (admin only)
 */
router.get(
  '/suspicious-activity',
  authMiddleware as any,
  roleMiddleware(['admin']) as any,
  securityController.getSuspiciousActivity as any
);

/**
 * POST /security/clear-failed-attempts
 * Clear failed login attempts (admin only)
 */
router.post(
  '/clear-failed-attempts',
  authMiddleware as any,
  roleMiddleware(['admin']) as any,
  validateRequest(clearFailedAttemptsSchema),
  securityController.clearFailedAttempts as any
);

/**
 * GET /security/audit-logs
 * Get audit logs (admin only)
 */
router.get(
  '/audit-logs',
  authMiddleware as any,
  roleMiddleware(['admin']) as any,
  securityController.getAuditLogs as any
);

export default router;
