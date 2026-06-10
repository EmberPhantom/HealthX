import { Router, RequestHandler } from 'express';
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

const router = Router();

const h = (fn: any): RequestHandler => fn;

/**
 * POST /auth/signup
 */
router.post(
  '/signup',
  h(authRateLimiter),
  h(validateRequest(signupSchema)),
  h(auditLog('SIGNUP')),
  h(authController.signup)
);

/**
 * POST /auth/login
 */
router.post(
  '/login',
  h(checkSuspiciousActivity),
  h(authRateLimiter),
  h(validateRequest(loginSchema)),
  h(trackLoginAttempt),
  h(auditLog('LOGIN')),
  h(authController.login)
);

/**
 * POST /auth/google
 */
router.post(
  '/google',
  h(authRateLimiter),
  h(validateRequest(googleAuthSchema)),
  h(authController.googleAuth)
);

/**
 * POST /auth/refresh
 */
router.post(
  '/refresh',
  h(authRateLimiter),
  h(validateRequest(refreshTokenSchema)),
  h(authController.refreshToken)
);

/**
 * POST /auth/logout
 */
router.post(
  '/logout',
  h(authMiddleware),
  h(validateRequest(refreshTokenSchema)),
  h(auditLog('LOGOUT')),
  h(authController.logout)
);

/**
 * GET /auth/me
 */
router.get('/me', h(authMiddleware), h(authController.getCurrentUser));

/**
 * PUT /auth/me
 */
router.put(
  '/me',
  h(authMiddleware),
  h(validateRequest(updateProfileSchema)),
  h(sensitiveOpRateLimiter),
  h(auditLog('PROFILE_UPDATE')),
  h(authController.updateCurrentUser)
);

/**
 * POST /auth/me/upload-picture
 */
router.post(
  '/me/upload-picture',
  h(authMiddleware),
  h(uploadAvatar),
  h(handleMulterError),
  h(sensitiveOpRateLimiter),
  h(authController.uploadCurrentUserPicture)
);

/**
 * POST /auth/link
 */
router.post(
  '/link',
  h(authMiddleware),
  h(sensitiveOpRateLimiter),
  h(authController.linkOAuthProvider)
);

/**
 * POST /auth/unlink
 */
router.post(
  '/unlink',
  h(authMiddleware),
  h(sensitiveOpRateLimiter),
  h(authController.unlinkOAuthProvider)
);

/**
 * POST /auth/forgot-password
 */
router.post(
  '/forgot-password',
  h(authRateLimiter),
  h(validateRequest(forgotPasswordSchema)),
  h(authController.forgotPassword)
);

/**
 * POST /auth/reset-password
 */
router.post(
  '/reset-password',
  h(authRateLimiter),
  h(validateRequest(resetPasswordSchema)),
  h(authController.resetPassword)
);

export default router;
