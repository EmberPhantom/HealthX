import { Request, Response } from 'express';
import onboardingService from '../services/onboarding.service';
import { catchAsync } from '../utils/catchAsync';

/**
 * POST /api/v1/onboarding/verify-email
 * Verify email with token
 */
export const verifyEmail = catchAsync(async (req: Request, res: Response) => {
  const { token } = req.body;

  if (!token) {
    return res.status(400).json({
      success: false,
      message: 'Verification token is required',
    });
  }

  const result = await onboardingService.verifyEmail(token);

  res.status(200).json({
    success: true,
    message: 'Email verified successfully',
    data: result,
  });
});

/**
 * POST /api/v1/onboarding/resend-verification
 * Resend verification email
 */
export const resendVerification = catchAsync(async (req: Request, res: Response) => {
  const userId = (req as any).user?.userId;

  if (!userId) {
    return res.status(401).json({
      success: false,
      message: 'Authentication required',
    });
  }

  const result = await onboardingService.resendVerificationEmail(userId);

  res.status(200).json({
    success: true,
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
export const completeOnboarding = catchAsync(async (req: Request, res: Response) => {
  const userId = (req as any).user?.userId;

  if (!userId) {
    return res.status(401).json({
      success: false,
      message: 'Authentication required',
    });
  }

  const {
    medicalHistory,
    allergies,
    medications,
    emergencyContactName,
    emergencyContactPhone,
    insuranceProvider,
    insurancePolicyNo,
  } = req.body;

  const result = await onboardingService.completeOnboarding(userId, {
    medicalHistory,
    allergies,
    medications,
    emergencyContactName,
    emergencyContactPhone,
    insuranceProvider,
    insurancePolicyNo,
  });

  res.status(200).json({
    success: true,
    message: result.message,
    data: result.profile,
  });
});

/**
 * GET /api/v1/onboarding/status
 * Get onboarding completion status
 */
export const getOnboardingStatus = catchAsync(async (req: Request, res: Response) => {
  const userId = (req as any).user?.userId;

  if (!userId) {
    return res.status(401).json({
      success: false,
      message: 'Authentication required',
    });
  }

  const status = await onboardingService.getOnboardingStatus(userId);

  res.status(200).json({
    success: true,
    message: 'Onboarding status retrieved',
    data: status,
  });
});
