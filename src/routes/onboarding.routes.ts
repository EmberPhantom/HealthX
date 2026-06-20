import { Router, RequestHandler } from 'express';
import * as onboardingController from '../controllers/onboarding.controller';
import { authMiddleware } from '../middlewares/auth.middleware';
import { validateRequest } from '../middlewares/validate.middleware';
import { authRateLimiter } from '../middlewares/rateLimit.middleware';
import {
  verifyEmailSchema,
  resendVerificationSchema,
  completeOnboardingSchema,
} from '../schemas/onboarding.schema';

const router = Router();

const h = (fn: any): RequestHandler => fn;

router.post('/verify-email', authRateLimiter, h(validateRequest(verifyEmailSchema)), h(onboardingController.verifyEmail));
router.post('/resend-verification', h(authMiddleware), authRateLimiter, h(validateRequest(resendVerificationSchema)), h(onboardingController.resendVerification));
router.post('/complete', h(authMiddleware), h(validateRequest(completeOnboardingSchema)), h(onboardingController.completeOnboarding));
router.get('/status', h(authMiddleware), h(onboardingController.getOnboardingStatus));

export default router;
