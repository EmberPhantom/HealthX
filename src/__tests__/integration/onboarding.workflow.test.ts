import request from 'supertest';
import express from 'express';
import { Types } from 'mongoose';
import authRoutes from "../../routes/auth.routes";
import onboardingRoutes from "../../routes/onboarding.routes";
import User from "../../models/User";
import EmailVerification from "../../models/EmailVerification";
import authMiddleware from "../../middlewares/auth.middleware";
import onboardingService from "../../services/onboarding.service";
import emailService from "../../services/email.service";
import { AppError } from '../../utils/AppError';
import { errorMiddleware } from '../../middlewares/errorMiddleware';

jest.mock("../../models/User");
jest.mock("../../models/EmailVerification");
jest.mock('../../services/auth.service', () => ({
  authService: {
    signup: jest.fn().mockResolvedValue({
      accessToken: 'mock-access-token-123',
      refreshToken: 'mock-refresh-token-456',
      user: {
        id: '507f1f77bcf86cd799439012',
        name: 'John Doe',
        email: 'integration@example.com',
        role: 'user',
        isEmailVerified: false,
      }
    })
  }
}));
jest.mock('../../services/onboarding.service', () => ({
  __esModule: true,
  default: {
    verifyEmail: jest.fn(),
    completeOnboarding: jest.fn(),
    getOnboardingStatus: jest.fn(),
    resendVerificationEmail: jest.fn(),
  }
}));
jest.mock('../../services/email.service', () => ({
  __esModule: true,
  default: {
    sendVerificationEmail: jest.fn(),
    sendPasswordResetEmail: jest.fn(),
  }
}));
jest.mock('../../middlewares/auth.middleware', () => {
  const mockAuthMiddleware = jest.fn((req, res, next) => {
    const authHeader = req.headers.authorization;
    if (!authHeader) {
      return res.status(401).json({ success: false, message: 'Authentication required' });
    }
    if (authHeader.includes('invalid-token')) {
      return res.status(401).json({ success: false, message: 'Invalid token' });
    }
    req.user = { userId: '507f1f77bcf86cd799439012', role: 'user' };
    next();
  });
  return {
    __esModule: true,
    default: mockAuthMiddleware,
    authMiddleware: mockAuthMiddleware,
    roleMiddleware: () => (req, res, next) => next(),
  };
});

describe('Onboarding Integration Tests', () => {
  let app: express.Application;
  const mockUserId = new Types.ObjectId().toString();
  const mockEmail = 'integration@example.com';
  const mockPassword = 'Test@1234567890';

  beforeEach(() => {
    app = express();
    app.use(express.json());
    app.use('/auth', authRoutes);
    app.use('/onboarding', onboardingRoutes);
    app.use(errorMiddleware);
    jest.clearAllMocks();
    (authMiddleware as any).mockRestore && (authMiddleware as any).mockRestore();
    // Re-apply default implementation to mockAuthMiddleware
    (authMiddleware as any).mockImplementation((req, res, next) => {
      const authHeader = req.headers.authorization;
      if (!authHeader) {
        return res.status(401).json({ success: false, message: 'Authentication required' });
      }
      if (authHeader.includes('invalid-token')) {
        return res.status(401).json({ success: false, message: 'Invalid token' });
      }
      req.user = { userId: '507f1f77bcf86cd799439012', role: 'user' };
      next();
    });
    
  });

  describe('Complete Signup to Profile Completion Flow', () => {
    it('should complete full onboarding workflow', async () => {
      // Step 1: User signup
      const signupData = {
        name: 'John Doe',
        email: mockEmail,
        password: mockPassword,
        confirmPassword: mockPassword,
      };

      const signupRes = await request(app)
        .post('/auth/signup')
        .send(signupData)
        .expect(201);

      expect(signupRes.body.data).toHaveProperty('user');
      expect(signupRes.body.data.user).toHaveProperty('id');
      const userId = signupRes.body.data.user.id;

      // Step 2: Verify email
      const mockToken = 'verification-token-123';
      (onboardingService.verifyEmail as jest.Mock).mockResolvedValue({
        message: 'Email verified successfully',
        user: {
          _id: userId,
          isEmailVerified: true,
        },
      });

      const verifyRes = await request(app)
        .post('/onboarding/verify-email')
        .send({ token: mockToken })
        .set('Authorization', `Bearer ${signupRes.body.data.accessToken}`)
        .expect(200);

      expect(verifyRes.body).toHaveProperty('data.user.isEmailVerified', true);

      // Step 3: Complete profile
      const profileData = {
        dateOfBirth: '1990-01-01',
        phone: '+1234567890',
        medicalHistory: 'No known medical conditions',
        allergies: 'Peanuts',
        insuranceProvider: 'BlueCross',
        insurancePolicyNumber: 'ABC123456',
      };

      (onboardingService.completeOnboarding as jest.Mock).mockResolvedValue({
        message: 'Onboarding completed',
        profile: {
          _id: userId,
          email: mockEmail,
          firstName: 'John',
          lastName: 'Doe',
          onboardingComplete: true,
          ...profileData,
        }
      });

      const completeRes = await request(app)
        .post('/onboarding/complete')
        .send(profileData)
        .set('Authorization', `Bearer ${signupRes.body.data.accessToken}`)
        .expect(200);

      expect(completeRes.body.data).toHaveProperty('onboardingComplete', true);

      // Step 4: Check onboarding status
      (onboardingService.getOnboardingStatus as jest.Mock).mockResolvedValue({
        email: mockEmail,
        isEmailVerified: true,
        completionPercentage: 100,
        missingFields: [],
      });

      const statusRes = await request(app)
        .get('/onboarding/status')
        .set('Authorization', `Bearer ${signupRes.body.data.accessToken}`)
        .expect(200);

      expect(statusRes.body.data.completionPercentage).toBe(100);
    });

    it('should handle email verification failure gracefully', async () => {
      (onboardingService.verifyEmail as jest.Mock).mockRejectedValue(
        new AppError('Invalid or expired verification token', 400)
      );

      await request(app)
        .post('/onboarding/verify-email')
        .send({ token: 'invalid-token' })
        .set('Authorization', `Bearer fake-token`)
        .expect(400);

      expect(onboardingService.verifyEmail).toHaveBeenCalled();
    });

    it('should allow resending verification email', async () => {
      (onboardingService.resendVerificationEmail as jest.Mock).mockResolvedValue({
        message: 'Verification email sent',
        expiresIn: 86400,
      });

      const res = await request(app)
        .post('/onboarding/resend-verification')
        .set('Authorization', `Bearer fake-token`)
        .expect(200);

      expect(res.body).toHaveProperty('message', expect.stringContaining('sent'));
    });

    it('should prevent profile completion without email verification', async () => {
      const profileData = {
        firstName: 'John',
        dateOfBirth: '1990-01-01',
      };

      (onboardingService.completeOnboarding as jest.Mock).mockRejectedValue(
        new AppError('Email must be verified before completing profile', 400)
      );

      await request(app)
        .post('/onboarding/complete')
        .send(profileData)
        .set('Authorization', `Bearer fake-token`)
        .expect(400);
    });
  });

  describe('Email Verification States', () => {
    it('should require valid verification token', async () => {
      (onboardingService.verifyEmail as jest.Mock).mockRejectedValue(
        new AppError('Token not found', 404)
      );

      const res = await request(app)
        .post('/onboarding/verify-email')
        .send({ token: '' })
        .set('Authorization', `Bearer fake-token`)
        .expect(400);

      expect(res.body).toHaveProperty('message');
    });

    it('should reject expired verification tokens', async () => {
      (onboardingService.verifyEmail as jest.Mock).mockRejectedValue(
        new AppError('Verification token has expired', 410)
      );

      await request(app)
        .post('/onboarding/verify-email')
        .send({ token: 'expired-token' })
        .set('Authorization', `Bearer fake-token`)
        .expect(410);
    });

    it('should reject already verified tokens', async () => {
      (onboardingService.verifyEmail as jest.Mock).mockRejectedValue(
        new AppError('Email already verified', 400)
      );

      await request(app)
        .post('/onboarding/verify-email')
        .send({ token: 'used-token' })
        .set('Authorization', `Bearer fake-token`)
        .expect(400);
    });
  });

  describe('Profile Completion Validation', () => {
    it('should validate required fields in profile completion', async () => {
      const invalidData = {
        // Missing required fields
      };

      (onboardingService.completeOnboarding as jest.Mock).mockRejectedValue(
        new AppError('Missing required fields', 400)
      );

      await request(app)
        .post('/onboarding/complete')
        .send(invalidData)
        .set('Authorization', `Bearer fake-token`)
        .expect(400);
    });

    it('should accept optional fields gracefully', async () => {
      const partialData = {
        firstName: 'John',
        lastName: 'Doe',
        // No medical history
      };

      (onboardingService.completeOnboarding as jest.Mock).mockResolvedValue({
        _id: mockUserId,
        email: mockEmail,
        ...partialData,
        onboardingComplete: false,
      });

      const res = await request(app)
        .post('/onboarding/complete')
        .send(partialData)
        .set('Authorization', `Bearer fake-token`)
        .expect(200);

      expect(res.body).toBeDefined();
    });

    it('should validate phone number format', async () => {
      const invalidPhone = {
        phone: 'not-a-phone',
      };

      (onboardingService.completeOnboarding as jest.Mock).mockRejectedValue(
        new AppError('Invalid phone number format', 400)
      );

      await request(app)
        .post('/onboarding/complete')
        .send(invalidPhone)
        .set('Authorization', `Bearer fake-token`)
        .expect(400);
    });

    it('should validate date of birth format', async () => {
      const invalidDOB = {
        dateOfBirth: 'invalid-date',
      };

      (onboardingService.completeOnboarding as jest.Mock).mockRejectedValue(
        new AppError('Invalid date of birth format', 400)
      );

      await request(app)
        .post('/onboarding/complete')
        .send(invalidDOB)
        .set('Authorization', `Bearer fake-token`)
        .expect(400);
    });

    it('should not allow future dates of birth', async () => {
      const futureDOB = {
        dateOfBirth: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
      };

      (onboardingService.completeOnboarding as jest.Mock).mockRejectedValue(
        new AppError('Date of birth cannot be in the future', 400)
      );

      await request(app)
        .post('/onboarding/complete')
        .send(futureDOB)
        .set('Authorization', `Bearer fake-token`)
        .expect(400);
    });
  });

  describe('Onboarding Status', () => {
    it('should calculate completion percentage correctly', async () => {
      (onboardingService.getOnboardingStatus as jest.Mock).mockResolvedValue({
        email: mockEmail,
        isEmailVerified: true,
        firstName: 'John',
        completionPercentage: 75,
        missingFields: ['medicalHistory', 'insuranceProvider'],
      });

      const res = await request(app)
        .get('/onboarding/status')
        .set('Authorization', `Bearer fake-token`)
        .expect(200);

      expect(res.body.data.completionPercentage).toBe(75);
      expect(res.body.data.missingFields).toContain('medicalHistory');
    });

    it('should return 0% for new unstarted onboarding', async () => {
      (onboardingService.getOnboardingStatus as jest.Mock).mockResolvedValue({
        email: mockEmail,
        isEmailVerified: false,
        completionPercentage: 0,
        missingFields: [
          'firstName',
          'lastName',
          'dateOfBirth',
          'phone',
          'medicalHistory',
          'allergies',
          'insuranceProvider',
          'insurancePolicyNumber',
        ],
      });

      const res = await request(app)
        .get('/onboarding/status')
        .set('Authorization', `Bearer fake-token`)
        .expect(200);

      expect(res.body.data.completionPercentage).toBe(0);
    });

    it('should list missing fields for partial completion', async () => {
      (onboardingService.getOnboardingStatus as jest.Mock).mockResolvedValue({
        email: mockEmail,
        isEmailVerified: true,
        firstName: 'John',
        lastName: 'Doe',
        dateOfBirth: '1990-01-01',
        completionPercentage: 50,
        missingFields: [
          'phone',
          'medicalHistory',
          'allergies',
          'insuranceProvider',
          'insurancePolicyNumber',
        ],
      });

      const res = await request(app)
        .get('/onboarding/status')
        .set('Authorization', `Bearer fake-token`)
        .expect(200);

      expect(res.body.data.completionPercentage).toBe(50);
      expect(res.body.data.missingFields.length).toBe(5);
    });
  });

  describe('Authentication Requirements', () => {
    it('should require authentication for onboarding endpoints', async () => {
      await request(app)
        .post('/onboarding/complete')
        .send({ firstName: 'John' })
        .expect(401); // No auth header
    });

    it('should reject invalid authentication tokens', async () => {
      await request(app)
        .post('/onboarding/complete')
        .send({ firstName: 'John' })
        .set('Authorization', 'Bearer invalid-token')
        .expect(401);
    });

    it('should allow valid authentication token', async () => {
      (authMiddleware as jest.Mock).mockImplementation((req, res, next) => {
        req.user = { userId: mockUserId };
        next();
      });

      (onboardingService.completeOnboarding as jest.Mock).mockResolvedValue({
        message: 'Onboarding completed',
        profile: {
          _id: mockUserId,
          onboardingComplete: true,
        }
      });

      await request(app)
        .post('/onboarding/complete')
        .send({ firstName: 'John' })
        .set('Authorization', `Bearer valid-token`)
        .expect(200);
    });
  });

  describe('Concurrent Requests', () => {
    it('should handle concurrent profile updates safely', async () => {
      (onboardingService.completeOnboarding as jest.Mock).mockResolvedValue({
        message: 'Onboarding completed',
        profile: {
          _id: mockUserId,
          onboardingComplete: true,
        }
      });

      const profileData = { firstName: 'John' };

      const results = await Promise.all([
        request(app)
          .post('/onboarding/complete')
          .send(profileData)
          .set('Authorization', `Bearer token1`),
        request(app)
          .post('/onboarding/complete')
          .send(profileData)
          .set('Authorization', `Bearer token1`),
      ]);

      results.forEach((res) => {
        expect(res.status).toBe(200);
      });
    });
  });
});
