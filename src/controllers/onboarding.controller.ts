import { Request, Response } from 'express';
import onboardingService from '../services/onboarding.service';
import { catchAsync } from '../utils/catchAsync';
import { AppError } from '../utils/AppError';
import { AuthRequest } from '../middlewares/auth.middleware';

/**
 * POST /api/v1/onboarding/verify-email
 * Verify email with token
 */
export const verifyEmail = catchAsync(async (req: Request, res: Response) => {
  const { token } = req.body;

  if (!token) {
    throw new AppError('Verification token is required', 400);
  }

  const result = await onboardingService.verifyEmail(token);

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    message: 'Email verified successfully',
    data: result,
  });
});

/**
 * POST /api/v1/onboarding/resend-verification
 * Resend verification email
 */
export const resendVerification = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('Authentication required', 401);
  }

  const result = await onboardingService.resendVerificationEmail(req.user.userId);

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    message: result.message,
    data: {
      expiresAt: result.expiresAt,
    },
  });
});

/**
 * POST /api/v1/onboarding/complete
 * Complete user onboarding profile
 */
export const completeOnboarding = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('Authentication required', 401);
  }

  const {
    medicalHistory,
    allergies,
    medications,
    emergencyContactName,
    emergencyContactPhone,
    insuranceProvider,
    insurancePolicyNo,
    height,
    weight,
    isDiabetesPatient,
    isBpPatient,
    wellnessGoals,
    dominantDosha,
    activityLevel,
    gender,
    dateOfBirth,
    phone,
    avatarUrl,
    age,
  } = req.body;

  const result = await onboardingService.completeOnboarding(req.user.userId, {
    medicalHistory,
    allergies,
    medications,
    emergencyContactName,
    emergencyContactPhone,
    insuranceProvider,
    insurancePolicyNo,
    height,
    weight,
    isDiabetesPatient,
    isBpPatient,
    wellnessGoals,
    dominantDosha,
    activityLevel,
    gender,
    dateOfBirth,
    phone,
    avatarUrl,
    age,
  });

  // Trigger Step 5 question generation asynchronously to pre-warm the AI cache/model
  if (process.env.NODE_ENV !== 'test') {
    const acceptLang = req.headers['accept-language'] || 'en';
    const locale = acceptLang.split(',')[0].split('-')[0].trim() || 'en';
    const userIdForWarmup = req.user.userId;
    import('../services/ai-health.service').then(({ default: aiService }) => {
      aiService.generateStep5Questions(userIdForWarmup, locale).catch((err) => {
        import('../utils/logger').then(({ default: log }) => {
          log.error(`[onboarding.controller] Error pre-generating Step 5 questions:`, err);
        });
      });
    });
  }

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    message: result.message,
    data: result.profile,
  });
});

/**
 * GET /api/v1/onboarding/status
 * Get onboarding completion status
 */
export const getOnboardingStatus = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('Authentication required', 401);
  }

  const status = await onboardingService.getOnboardingStatus(req.user.userId);

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    message: 'Onboarding status retrieved',
    data: status,
  });
});
