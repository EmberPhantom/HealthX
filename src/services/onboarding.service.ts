import { v4 as uuidv4 } from 'uuid';
import EmailVerification from '../models/EmailVerification';
import User from '../models/User';
import Patient from '../models/Patient';
import emailService from './email.service';
import { AppError } from '../utils/AppError';

class OnboardingService {
  /**
   * Generate and send verification email
   */
  async sendVerificationEmail(userId: string, email: string, userName: string = 'User'): Promise<{ token: string; expiresAt: Date; email: string; expiresIn: number }> {
    try {
      // Generate unique verification token
      const token = uuidv4();
      const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours

      // Save verification record
      let emailVerification = await EmailVerification.findOne({ userId });
      if (emailVerification) {
        await EmailVerification.updateOne(
          { userId },
          {
            token,
            email,
            expiresAt,
            isVerified: false,
          }
        );
      } else {
        await EmailVerification.create({
          userId,
          email,
          token,
          expiresAt,
        });
      }

      // Build verification link
      const baseUrl = process.env.FRONTEND_URL || 'http://localhost:3000';
      const verificationLink = `${baseUrl}/verify-email?token=${token}`;

      // Send verification email
      const sent = await emailService.sendVerificationEmail(email, verificationLink, userName);
      if (!sent) {
        throw new AppError('Failed to send verification email', 500);
      }

      return {
        token,
        expiresAt,
        email,
        expiresIn: 24 * 60 * 60 * 1000,
      };
    } catch (error) {
      throw error;
    }
  }

  /**
   * Verify email with token
   */
  async verifyEmail(tokenOrUserId: string, optionalToken?: string): Promise<{ userId: string; email: string; message: string }> {
    try {
      const token = optionalToken || tokenOrUserId;
      const emailVerification = await EmailVerification.findOne({ token });

      if (!emailVerification) {
        throw new AppError('Invalid or expired verification token', 400);
      }

      if (emailVerification.isVerified) {
        throw new AppError('Email already verified', 400);
      }

      if (new Date() > emailVerification.expiresAt) {
        throw new AppError('Verification token has expired', 400);
      }

      // Mark as verified
      emailVerification.isVerified = true;
      emailVerification.verifiedAt = new Date();
      await emailVerification.save();

      // Update user's isEmailVerified flag
      const user = await User.findByIdAndUpdate(emailVerification.userId, { isEmailVerified: true }, { new: true });
      if (!user) {
        throw new AppError('User not found', 404);
      }

      // Send welcome email
      await emailService.sendWelcomeEmail(emailVerification.email, user.name);

      return {
        userId: emailVerification.userId.toString(),
        email: emailVerification.email,
        message: 'Email verified successfully',
      };
    } catch (error) {
      throw error;
    }
  }

  /**
   * Resend verification email
   */
  async resendVerificationEmail(userId: string, email?: string): Promise<{ message: string; expiresAt: Date }> {
    try {
      const user = await User.findById(userId);
      if (!user) {
        throw new AppError('User not found', 404);
      }

      if (user.isEmailVerified) {
        throw new AppError('Email already verified', 400);
      }

      // Delete any existing verification token
      await EmailVerification.deleteOne({ userId });

      // Generate new token
      const { expiresAt } = await this.sendVerificationEmail(userId, user.email, user.name);

      return {
        message: 'Verification email sent successfully',
        expiresAt,
      };
    } catch (error) {
      throw error;
    }
  }

  /**
   * Complete user onboarding (profile setup)
   */
  async completeOnboarding(userId: string, onboardingData: any): Promise<any> {
    try {
      const updatedUser = await User.findByIdAndUpdate(
        userId,
        { ...onboardingData, onboardingComplete: true },
        { new: true, select: '-password' }
      );

      if (!updatedUser) {
        throw new AppError('User not found', 404);
      }

      // Update or create patient profile for separate Mongoose model architecture
      let patient = await Patient.findOne({ userId });

      if (!patient) {
        patient = await Patient.create({
          userId,
          medicalHistory: onboardingData.medicalHistory || '',
          allergies: onboardingData.allergies ? (Array.isArray(onboardingData.allergies) ? onboardingData.allergies : [onboardingData.allergies]) : [],
          medications: onboardingData.medications ? (Array.isArray(onboardingData.medications) ? onboardingData.medications : [onboardingData.medications]) : [],
          emergencyContact: {
            name: onboardingData.emergencyContactName || '',
            phone: onboardingData.emergencyContactPhone || '',
          },
          insuranceProvider: onboardingData.insuranceProvider || '',
          insurancePolicyNo: onboardingData.insurancePolicyNumber || onboardingData.insurancePolicyNo || '',
          height: onboardingData.height,
          weight: onboardingData.weight,
          isDiabetesPatient: onboardingData.isDiabetesPatient,
          isBpPatient: onboardingData.isBpPatient,
        });
      } else {
        patient.medicalHistory = onboardingData.medicalHistory || patient.medicalHistory;
        patient.allergies = onboardingData.allergies ? (Array.isArray(onboardingData.allergies) ? onboardingData.allergies : [onboardingData.allergies]) : patient.allergies;
        patient.medications = onboardingData.medications ? (Array.isArray(onboardingData.medications) ? onboardingData.medications : [onboardingData.medications]) : patient.medications;
        patient.emergencyContact = {
          name: onboardingData.emergencyContactName || patient.emergencyContact?.name || '',
          phone: onboardingData.emergencyContactPhone || patient.emergencyContact?.phone || '',
          relation: patient.emergencyContact?.relation || 'Other',
        };
        patient.insuranceProvider = onboardingData.insuranceProvider || patient.insuranceProvider;
        patient.insurancePolicyNo = onboardingData.insurancePolicyNumber || onboardingData.insurancePolicyNo || patient.insurancePolicyNo;
        if (onboardingData.height !== undefined) patient.height = onboardingData.height;
        if (onboardingData.weight !== undefined) patient.weight = onboardingData.weight;
        if (onboardingData.isDiabetesPatient !== undefined) patient.isDiabetesPatient = onboardingData.isDiabetesPatient;
        if (onboardingData.isBpPatient !== undefined) patient.isBpPatient = onboardingData.isBpPatient;
        await patient.save();
      }

      const result: any = {
        ...(typeof updatedUser.toObject === 'function' ? updatedUser.toObject() : updatedUser),
      };

      result.message = 'Onboarding completed successfully';
      result.profile = {
        user: updatedUser,
        patient: patient,
      };
      result.onboardingComplete = true;

      return result;
    } catch (error) {
      throw error;
    }
  }

  /**
   * Get onboarding status
   */
  async getOnboardingStatus(userId: string): Promise<any> {
    try {
      const user = await User.findById(userId);
      if (!user) {
        throw new AppError('User not found', 404);
      }

      const patient = await Patient.findOne({ userId });

      let completionPercentage = 0;
      let profileCompleted = false;

      if (user.isEmailVerified) {
        completionPercentage += 50;
      }

      if (patient && patient.medicalHistory) {
        completionPercentage += 25;
      }

      if (patient?.emergencyContact?.name) {
        completionPercentage += 15;
      }

      if (patient && patient.insuranceProvider) {
        completionPercentage += 10;
      }

      profileCompleted = completionPercentage >= 90;

      return {
        email: user.email,
        isEmailVerified: user.isEmailVerified,
        emailVerified: user.isEmailVerified,
        profileCompleted,
        completionPercentage,
      };
    } catch (error) {
      throw error;
    }
  }
}

export default new OnboardingService();
