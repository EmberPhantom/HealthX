import User from '../models/User';
import Patient from '../models/Patient';
import { AppError } from '../utils/AppError';
import mongoose from 'mongoose';
import logger from '../utils/logger';

interface GoogleProfile {
  id: string;
  displayName: string;
  emails?: { value: string; verified?: boolean }[];
  photos?: { value: string }[];
  username?: string;
}

class OAuthService {
  async handleOAuthLogin(
    provider: 'google',
    profile: any,
    accessToken?: string,
    refreshToken?: string
  ) {
    const email = this.getEmailFromProfile(profile);
    const providerId = profile.id;
    const idField = `${provider}Id`;

    // 1. Check if user exists with this provider ID
    let user = await User.findOne({ [idField]: providerId });

    if (user) {
      if (refreshToken && `${provider}RefreshToken` in user) {
        (user as any)[`${provider}RefreshToken`] = refreshToken;
        await user.save();
      }
      const result: any = user;
      result.user = user;
      result.isNewUser = false;
      result.linkedAccount = false;
      return result;
    }

    // 2. Check for account linking (same email)
    if (email) {
      user = await User.findOne({ email });
      if (user) {
        (user as any)[idField] = providerId;
        if (refreshToken && `${provider}RefreshToken` in user) {
          (user as any)[`${provider}RefreshToken`] = refreshToken;
        }

        const avatarUrl = this.getAvatarFromProfile(profile);
        if (!user.avatarUrl && avatarUrl) {
          user.avatarUrl = avatarUrl;
        }

        await user.save();

        const result: any = user;
        result.user = user;
        result.isNewUser = false;
        result.linkedAccount = true;
        return result;
      }
    }

    // 3. Create new user
    const createData: any = {
      name: profile.displayName || profile.username || 'OAuth User',
      email: email || `${provider}_${providerId}@healthx.local`,
      phone: '',
      [idField]: providerId,
      avatarUrl: this.getAvatarFromProfile(profile),
      isEmailVerified: !!email,
      role: 'user',
    };
    if (refreshToken) {
      createData[`${provider}RefreshToken`] = refreshToken;
    }

    const newUser = await User.create(createData);

    // Create patient profile
    try {
      await Patient.create({
        userId: newUser._id,
        allergies: [],
        medications: [],
      });
    } catch (err: any) {
      logger.error('Patient creation error:', err);
    }

    const result: any = newUser;
    result.user = newUser;
    result.isNewUser = true;
    result.linkedAccount = false;
    return result;
  }

  async linkOAuthProvider(
    userId: string,
    provider: string,
    profile: any
  ) {
    const user = await User.findById(userId);
    if (!user) {
      throw new AppError('User not found', 404);
    }

    const idField = `${provider}Id`;

    const existing = await User.findOne({ [idField]: profile.id });
    if (existing && existing._id.toString() !== userId) {
      throw new AppError('This account is already linked to another user', 400);
    }

    if ((user as any)[idField] === profile.id) {
      throw new AppError('This account is already linked to you', 400);
    }

    (user as any)[idField] = profile.id;
    await user.save();
    return user;
  }

  async unlinkOAuthProvider(
    userId: string,
    provider: string,
    password?: string | null
  ) {
    const user = await User.findById(userId);

    if (!user) {
      throw new AppError('User not found', 404);
    }

    const idField = `${provider}Id`;

    if (!(user as any)[idField]) {
      throw new AppError(`${provider} is not linked to your account`, 400);
    }

    let loginMethodsCount = 0;
    if (user.password) loginMethodsCount++;
    if ((user as any).googleId) loginMethodsCount++;

    if (loginMethodsCount <= 1) {
      throw new AppError(
        `Cannot unlink ${provider} because you have no password. Please set a password first.`,
        400
      );
    }

    (user as any)[idField] = undefined;
    (user as any)[`${provider}RefreshToken`] = undefined;
    await user.save();

    return user;
  }

  async getLinkedProviders(userOrUserId: any): Promise<string[]> {
    let user = userOrUserId;
    if (typeof userOrUserId === 'string' || (userOrUserId && mongoose.isValidObjectId(userOrUserId))) {
      user = await User.findById(userOrUserId);
      if (!user) {
        throw new AppError('User not found', 404);
      }
    }

    const providers: string[] = [];
    if (user.googleId) providers.push('google');
    if (user.password) providers.push('password');
    return providers;
  }

  async verifyOAuthState(stateToken: string): Promise<boolean> {
    return typeof stateToken === 'string' && stateToken.length > 0;
  }

  async getGoogleAuthUrl(state: string): Promise<string> {
    return `https://accounts.google.com/o/oauth2/v2/auth?state=${state}`;
  }

  private getEmailFromProfile(profile: any): string | undefined {
    if (profile.emails && profile.emails.length > 0) {
      const email =
        profile.emails.find((e: any) => e.primary || e.verified) ||
        profile.emails[0];
      return email.value;
    }
    return undefined;
  }

  private getAvatarFromProfile(profile: any): string | undefined {
    if (profile.photos && profile.photos.length > 0) {
      return profile.photos[0].value;
    }
    return undefined;
  }
}

export default new OAuthService();
