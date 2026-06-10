import onboardingService from '../../../services/onboarding.service';
import emailService from '../../../services/email.service';
import User from '../../../models/User';
import Patient from '../../../models/Patient';
import EmailVerification from '../../../models/EmailVerification';
import AppError from '../../../utils/AppError';
import { Types } from 'mongoose';

jest.mock('../../../services/email.service');
jest.mock('../../../models/User');
jest.mock('../../../models/EmailVerification');

describe('OnboardingService', () => {
  const mockUserId = new Types.ObjectId().toString();
  const mockEmail = 'test@example.com';
  const mockToken = 'test-verification-token-123';
  const mockUser = {
    _id: mockUserId,
    email: mockEmail,
    firstName: 'Test',
    lastName: 'User',
    isEmailVerified: false,
    save: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    await Patient.deleteMany({});
  });

  describe('sendVerificationEmail', () => {
    it('should send verification email and create EmailVerification record', async () => {
      const mockEmailVerif = {
        _id: new Types.ObjectId(),
        userId: mockUserId,
        email: mockEmail,
        token: mockToken,
        save: jest.fn(),
      };

      (EmailVerification.create as jest.Mock).mockResolvedValue(mockEmailVerif);
      (emailService.sendVerificationEmail as jest.Mock).mockResolvedValue(true);

      const result = await onboardingService.sendVerificationEmail(mockUserId, mockEmail);

      expect(result).toEqual(expect.objectContaining({
        email: mockEmail,
        expiresIn: expect.any(Number),
      }));
      expect(emailService.sendVerificationEmail).toHaveBeenCalledWith(
        mockEmail,
        expect.any(String),
        expect.any(String)
      );
    });

    it('should throw error if EmailVerification.create fails', async () => {
      (EmailVerification.create as jest.Mock).mockRejectedValue(
        new Error('Database error')
      );

      await expect(
        onboardingService.sendVerificationEmail(mockUserId, mockEmail)
      ).rejects.toThrow();
    });

    it('should throw error if email sending fails', async () => {
      const mockEmailVerif = {
        _id: new Types.ObjectId(),
        userId: mockUserId,
        email: mockEmail,
        token: mockToken,
      };

      (EmailVerification.create as jest.Mock).mockResolvedValue(mockEmailVerif);
      (emailService.sendVerificationEmail as jest.Mock).mockRejectedValue(
        new Error('Email service error')
      );

      await expect(
        onboardingService.sendVerificationEmail(mockUserId, mockEmail)
      ).rejects.toThrow();
    });
  });

  describe('verifyEmail', () => {
    it('should verify email successfully', async () => {
      const mockEmailVerif = {
        userId: mockUserId,
        email: mockEmail,
        token: mockToken,
        isVerified: false,
        expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000),
        save: jest.fn(),
      };

      (EmailVerification.findOne as jest.Mock).mockResolvedValue(mockEmailVerif);
      (User.findByIdAndUpdate as jest.Mock).mockResolvedValue({
        ...mockUser,
        isEmailVerified: true,
      });

      const result = await onboardingService.verifyEmail(mockUserId, mockToken);

      expect(result).toHaveProperty('message', expect.stringContaining('verified'));
      expect(mockEmailVerif.save).toHaveBeenCalled();
      expect(User.findByIdAndUpdate).toHaveBeenCalledWith(
        mockUserId,
        { isEmailVerified: true },
        { new: true }
      );
    });

    it('should throw error if token not found', async () => {
      (EmailVerification.findOne as jest.Mock).mockResolvedValue(null);

      await expect(
        onboardingService.verifyEmail(mockUserId, 'invalid-token')
      ).rejects.toThrow(AppError);
    });

    it('should throw error if token expired', async () => {
      const expiredToken = {
        userId: mockUserId,
        token: mockToken,
        expiresAt: new Date(Date.now() - 1000), // Past date
      };

      (EmailVerification.findOne as jest.Mock).mockResolvedValue(expiredToken);

      await expect(
        onboardingService.verifyEmail(mockUserId, mockToken)
      ).rejects.toThrow(AppError);
    });

    it('should throw error if already verified', async () => {
      const verifiedToken = {
        userId: mockUserId,
        token: mockToken,
        isVerified: true,
        expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000),
      };

      (EmailVerification.findOne as jest.Mock).mockResolvedValue(verifiedToken);

      await expect(
        onboardingService.verifyEmail(mockUserId, mockToken)
      ).rejects.toThrow();
    });
  });

  describe('resendVerificationEmail', () => {
    it('should resend verification email successfully', async () => {
      const oldEmailVerif = {
        _id: new Types.ObjectId(),
        userId: mockUserId,
        email: mockEmail,
      };

      const newEmailVerif = {
        _id: new Types.ObjectId(),
        userId: mockUserId,
        email: mockEmail,
        token: 'new-token',
        save: jest.fn(),
      };

      (User.findById as jest.Mock).mockResolvedValue(mockUser);
      (EmailVerification.findOne as jest.Mock).mockResolvedValue(oldEmailVerif);
      (EmailVerification.deleteOne as jest.Mock).mockResolvedValue({ acknowledged: true });
      (EmailVerification.create as jest.Mock).mockResolvedValue(newEmailVerif);
      (emailService.sendVerificationEmail as jest.Mock).mockResolvedValue(true);

      const result = await onboardingService.resendVerificationEmail(mockUserId, mockEmail);

      expect(result).toHaveProperty('message', expect.stringContaining('sent'));
      expect(EmailVerification.deleteOne).toHaveBeenCalled();
      expect(emailService.sendVerificationEmail).toHaveBeenCalled();
    });

    it('should throw error if user not found', async () => {
      (User.findById as jest.Mock).mockResolvedValue(null);
      (EmailVerification.findOne as jest.Mock).mockResolvedValue(null);

      await expect(
        onboardingService.resendVerificationEmail(mockUserId, mockEmail)
      ).rejects.toThrow();
    });
  });

  describe('completeOnboarding', () => {
    it('should complete onboarding with profile data', async () => {
      const completeProfileData = {
        firstName: 'John',
        lastName: 'Doe',
        dateOfBirth: '1990-01-01',
        phone: '+1234567890',
        medicalHistory: 'None',
        allergies: 'Peanuts',
        insuranceProvider: 'BlueCross',
        insurancePolicyNumber: 'ABC123',
      };

      (User.findById as jest.Mock).mockResolvedValue(mockUser);
      (User.findByIdAndUpdate as jest.Mock).mockResolvedValue({
        ...mockUser,
        ...completeProfileData,
        onboardingComplete: true,
      });

      const result = await onboardingService.completeOnboarding(
        mockUserId,
        completeProfileData
      );

      expect(result).toHaveProperty('onboardingComplete', true);
      expect(User.findByIdAndUpdate).toHaveBeenCalledWith(
        mockUserId,
        expect.objectContaining(completeProfileData),
        { new: true, select: '-password' }
      );
    });

    it('should throw error if update fails', async () => {
      (User.findByIdAndUpdate as jest.Mock).mockRejectedValue(
        new Error('Database error')
      );

      await expect(
        onboardingService.completeOnboarding(mockUserId, {
          firstName: 'John',
        })
      ).rejects.toThrow();
    });
  });

  describe('getOnboardingStatus', () => {
    it('should return onboarding status with completion percentage', async () => {
      const completeUser = {
        _id: mockUserId,
        email: mockEmail,
        isEmailVerified: true,
        firstName: 'John',
        lastName: 'Doe',
        phone: '+1234567890',
        dateOfBirth: '1990-01-01',
        medicalHistory: 'None',
        allergies: 'Peanuts',
        insuranceProvider: 'BlueCross',
      };

      (User.findById as jest.Mock).mockResolvedValue(completeUser);

      const result = await onboardingService.getOnboardingStatus(mockUserId);

      expect(result).toHaveProperty('email', mockEmail);
      expect(result).toHaveProperty('isEmailVerified', true);
      expect(result).toHaveProperty('completionPercentage');
      expect(result.completionPercentage).toBeGreaterThan(0);
    });

    it('should return 0% for new user', async () => {
      (User.findById as jest.Mock).mockResolvedValue({
        ...mockUser,
        onboardingComplete: false,
      });

      const result = await onboardingService.getOnboardingStatus(mockUserId);

      expect(result.completionPercentage).toBe(0);
    });

    it('should throw error if user not found', async () => {
      (User.findById as jest.Mock).mockResolvedValue(null);

      await expect(
        onboardingService.getOnboardingStatus(mockUserId)
      ).rejects.toThrow();
    });
  });
});
