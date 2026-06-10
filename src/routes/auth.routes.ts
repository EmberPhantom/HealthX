import express, { Router } from 'express';
import * as authController from '../controllers/auth.controller';
import { validateRequest } from '../middlewares/validate.middleware';
import {
  signupSchema,
  loginSchema,
  googleAuthSchema,
  refreshTokenSchema,
  updateProfileSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
} from '../schemas/auth.schema';
import { authMiddleware } from '../middlewares/auth.middleware';
import { authRateLimiter, sensitiveOpRateLimiter } from '../middlewares/rateLimit.middleware';
import { trackLoginAttempt, auditLog, checkSuspiciousActivity } from '../middlewares/audit.middleware';
import { uploadAvatar, handleMulterError } from '../middlewares/upload.middleware';

// NOTE: CSRF middleware is intentionally NOT applied to these routes.
// The Flutter mobile client uses stateless JWT Bearer token auth — CSRF protection
// via synchronizer tokens is only applicable to browser cookie-based sessions.
// For mobile API security, we rely on: JWT Bearer tokens, rate limiting, and audit logging.

const router: Router = express.Router();

/**
 * POST /auth/signup
 */
router.post(
  '/signup',
  authRateLimiter as any,
  validateRequest(signupSchema),
  auditLog('SIGNUP') as any,
  authController.signup as any
);

/**
 * POST /auth/login
 */
router.post(
  '/login',
  checkSuspiciousActivity as any,
  authRateLimiter as any,
  validateRequest(loginSchema),
  trackLoginAttempt as any,
  auditLog('LOGIN') as any,
  authController.login as any
);

/**
 * POST /auth/google
 * Google OAuth — accepts idToken from Flutter (Google Sign-In SDK)
 */
router.post(
  '/google',
  authRateLimiter as any,
  validateRequest(googleAuthSchema),
  authController.googleAuth as any
);

/**
 * POST /auth/refresh
 */
router.post(
  '/refresh',
  authRateLimiter as any,
  validateRequest(refreshTokenSchema),
  authController.refreshToken as any
);

/**
 * POST /auth/logout
 * CSRF removed: mobile clients use JWT Bearer — no CSRF risk
 */
router.post(
  '/logout',
  authMiddleware as any,
  validateRequest(refreshTokenSchema),
  auditLog('LOGOUT') as any,
  authController.logout as any
);

/**
 * GET /auth/me
 */
router.get('/me', authMiddleware as any, authController.getCurrentUser as any);

/**
 * PUT /auth/me
 * CSRF removed: mobile clients use JWT Bearer — no CSRF risk
 */
router.put(
  '/me',
  authMiddleware as any,
  validateRequest(updateProfileSchema),
  sensitiveOpRateLimiter as any,
  auditLog('PROFILE_UPDATE') as any,
  authController.updateProfile as any
);

/**
 * POST /auth/me/upload-picture
 * CSRF removed: mobile clients use JWT Bearer — no CSRF risk
 * Multer field name changed to 'file' to match Flutter ApiService
 */
router.post(
  '/me/upload-picture',
  authMiddleware as any,
  uploadAvatar as any,
  handleMulterError as any,
  sensitiveOpRateLimiter as any,
  authController.uploadProfilePicture as any
);

/**
 * POST /auth/link
 * Link Google provider to account
 */
router.post(
  '/link',
  authMiddleware as any,
  sensitiveOpRateLimiter as any,
  authController.linkOAuthProvider as any
);

/**
 * POST /auth/unlink
 * Unlink Google provider from account
 */
router.post(
  '/unlink',
  authMiddleware as any,
  sensitiveOpRateLimiter as any,
  authController.unlinkOAuthProvider as any
);

/**
 * POST /auth/forgot-password
 */
router.post(
  '/forgot-password',
  authRateLimiter as any,
  validateRequest(forgotPasswordSchema),
  authController.forgotPassword as any
);

/**
 * POST /auth/reset-password
 */
router.post(
  '/reset-password',
  authRateLimiter as any,
  validateRequest(resetPasswordSchema),
  authController.resetPassword as any
);

export default router;
