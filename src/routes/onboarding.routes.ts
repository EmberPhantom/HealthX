import { Router, RequestHandler } from 'express';
import * as onboardingController from '../controllers/onboarding.controller';
import { authMiddleware } from '../middlewares/auth.middleware';

const router = Router();

const h = (fn: any): RequestHandler => fn;

router.post('/verify-email', h(onboardingController.verifyEmail));
router.post('/resend-verification', h(authMiddleware), h(onboardingController.resendVerification));
router.post('/complete', h(authMiddleware), h(onboardingController.completeOnboarding));
router.get('/status', h(authMiddleware), h(onboardingController.getOnboardingStatus));

export default router;
