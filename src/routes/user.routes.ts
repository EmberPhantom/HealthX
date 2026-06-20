import { Router, RequestHandler } from 'express';
import * as userController from '../controllers/user.controller';
import { validateRequest } from '../middlewares/validate.middleware';
import { updateProfileSchema } from '../schemas/auth.schema';
import { updateSettingsSchema, toggleFavoriteSchema, updateWellnessGoalsSchema, setAppRatingSchema, updatePointsSchema } from '../schemas/user.schema';
import { authMiddleware } from '../middlewares/auth.middleware';
import { uploadAvatar, handleMulterError } from '../middlewares/upload.middleware';
import { sensitiveOpRateLimiter } from '../middlewares/rateLimit.middleware';

const router = Router();

const h = (fn: any): RequestHandler => fn;

router.get('/me', h(authMiddleware), h(userController.getProfile));
router.get('/me/stats', h(authMiddleware), h(userController.getStats));
router.get('/me/settings', h(authMiddleware), h(userController.getSettings));
router.put('/me/settings', h(authMiddleware), h(validateRequest(updateSettingsSchema)), h(userController.updateSettings));
router.post('/me/favorites/toggle', h(authMiddleware), h(validateRequest(toggleFavoriteSchema)), h(userController.toggleFavorite));
router.put('/me/wellness-goals', h(authMiddleware), h(validateRequest(updateWellnessGoalsSchema)), h(userController.updateWellnessGoals));
router.post('/me/rating', h(authMiddleware), h(validateRequest(setAppRatingSchema)), h(userController.setAppRating));
router.patch('/me/points', h(authMiddleware), h(validateRequest(updatePointsSchema)), h(userController.updatePoints));

router.put(
  '/me',
  h(authMiddleware),
  h(validateRequest(updateProfileSchema)),
  h(userController.updateProfile)
);

router.post(
  '/me/upload-picture',
  h(authMiddleware),
  h(uploadAvatar),
  h(handleMulterError),
  h(sensitiveOpRateLimiter),
  h(userController.uploadPicture)
);

router.delete(
  '/me',
  h(authMiddleware),
  h(sensitiveOpRateLimiter),
  h(userController.deleteAccount)
);

export default router;
