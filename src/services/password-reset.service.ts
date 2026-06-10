import { randomBytes } from 'crypto';
import User from '../models/User';
import PasswordReset, { IPasswordReset } from '../models/PasswordReset';
import emailService from './email.service';
import { AppError } from '../utils/AppError';
import { config } from '../config/config';
import logger from '../utils/logger';

export class PasswordResetService {
  /**
   * Request password reset token
   * Always returns true (prevents email enumeration)
   */
  async requestReset(email: string): Promise<boolean> {
    try {
      const normalizedEmail = email.trim().toLowerCase();
      const user = await User.findOne({ email: normalizedEmail });
      
      if (!user) {
        logger.info(`Password reset requested for non-existent email: ${normalizedEmail}`);
        return true;
      }

      // Invalidate existing unused reset tokens for this user
      await PasswordReset.deleteMany({ userId: user._id, isUsed: false });

      // Generate secure 32-byte token
      const token = randomBytes(32).toString('hex');
      
      // Expire in 1 hour
      const expiresAt = new Date(Date.now() + 3600 * 1000);

      await PasswordReset.create({
        userId: user._id,
        email: normalizedEmail,
        token,
        expiresAt,
      });

      // Construct reset link
      const baseUrl = config.frontend.url || 'http://localhost:3000';
      const resetLink = `${baseUrl}/reset-password?token=${token}`;

      // Send the email
      await emailService.sendPasswordResetEmail(normalizedEmail, resetLink, user.name);
      
      logger.info(`Password reset email sent to: ${normalizedEmail}`);
      return true;
    } catch (error) {
      logger.error('Error in requestReset service:', error);
      throw error;
    }
  }

  /**
   * Validate a reset token and return the record
   */
  async validateToken(token: string): Promise<IPasswordReset> {
    const resetRecord = await PasswordReset.findOne({
      token,
      isUsed: false,
      expiresAt: { $gt: new Date() },
    });

    if (!resetRecord) {
      throw new AppError('Invalid or expired password reset token', 400);
    }

    return resetRecord;
  }

  /**
   * Reset user password
   */
  async resetPassword(token: string, newPassword: string): Promise<boolean> {
    try {
      const resetRecord = await this.validateToken(token);

      const user = await User.findById(resetRecord.userId).select('+password');
      if (!user) {
        throw new AppError('User not found', 404);
      }

      // Update password (pre-save middleware in User.ts will hash it)
      user.password = newPassword;
      await user.save();

      // Mark token as used
      resetRecord.isUsed = true;
      resetRecord.usedAt = new Date();
      await resetRecord.save();

      logger.info(`Password successfully reset for user ID: ${user._id}`);
      return true;
    } catch (error) {
      logger.error('Error in resetPassword service:', error);
      throw error;
    }
  }
}

export const passwordResetService = new PasswordResetService();
