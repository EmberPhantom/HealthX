import express, { Router } from 'express';
import * as userController from '../controllers/user.controller';
import { validateRequest } from '../middlewares/validate.middleware';
import { updateProfileSchema } from '../schemas/auth.schema';
import { authMiddleware } from '../middlewares/auth.middleware';
import { uploadAvatar, handleMulterError } from '../middlewares/upload.middleware';
import { sensitiveOpRateLimiter } from '../middlewares/rateLimit.middleware';

// NOTE: CSRF removed from all routes — mobile JWT Bearer auth does not require CSRF protection.

const router: Router = express.Router();

/**
 * GET /users/me  (also aliased as GET /users/profile for Flutter compatibility)
 */
router.get('/me', authMiddleware as any, userController.me as any);
router.get('/me/stats', authMiddleware as any, userController.getStats as any);
router.get('/me/settings', authMiddleware as any, userController.getSettings as any);
router.put('/me/settings', authMiddleware as any, userController.updateSettings as any);
router.post('/me/favorites/toggle', authMiddleware as any, userController.toggleFavorite as any);
router.put('/me/wellness-goals', authMiddleware as any, userController.updateWellnessGoals as any);
router.post('/me/rating', authMiddleware as any, userController.setAppRating as any);
router.patch('/me/points', authMiddleware as any, userController.updatePoints as any);
router.get('/profile', authMiddleware as any, userController.me as any);

/**
 * PUT /users/me  (also aliased as PUT /users/profile for Flutter compatibility)
 */
router.put(
  '/me',
  authMiddleware as any,
  validateRequest(updateProfileSchema),
  userController.updateMe as any
);
router.put(
  '/profile',
  authMiddleware as any,
  validateRequest(updateProfileSchema),
  userController.updateMe as any
);

/**
 * POST /users/me/upload-picture
 * Multer field: 'file' (matches Flutter ApiService.uploadProfilePicture fileKey: 'file')
 */
router.post(
  '/me/upload-picture',
  authMiddleware as any,
  uploadAvatar as any,
  handleMulterError as any,
  sensitiveOpRateLimiter as any,
  userController.uploadPicture as any
);

/**
 * DELETE /users/me
 * Delete account and all personal data (GDPR)
 */
router.delete(
  '/me',
  authMiddleware as any,
  sensitiveOpRateLimiter as any,
  userController.deleteAccount as any
);

export default router;
