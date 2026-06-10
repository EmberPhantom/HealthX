import { Router } from 'express';
import * as onboardingController from '../controllers/onboarding.controller';
import { authMiddleware } from '../middlewares/auth.middleware';

const router = Router();

// Public routes
router.post('/verify-email', onboardingController.verifyEmail as any);

// Protected routes
router.post('/resend-verification', authMiddleware as any, onboardingController.resendVerification as any);
router.post('/complete', authMiddleware as any, onboardingController.completeOnboarding as any);
router.get('/status', authMiddleware as any, onboardingController.getOnboardingStatus as any);

export default router;
