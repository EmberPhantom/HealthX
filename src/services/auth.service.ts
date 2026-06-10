import jwt from 'jsonwebtoken';
import { randomBytes } from 'crypto';
import { config } from '../config/config';
import User, { IUser } from '../models/User';
import Patient from '../models/Patient';
import { AppError } from '../utils/AppError';
import cacheService from './cache.service';
import onboardingService from './onboarding.service';
import logger from '../utils/logger';

interface TokenPayload {
  userId: string;
  role: string;
  iat: number;
  exp: number;
}

interface AuthResponse {
  accessToken: string;
  refreshToken: string;
  expiresAt: string;
  user: {
    id: string;
    name: string;
    email: string;
    role: string;
    isEmailVerified: boolean;
    onboardingComplete: boolean;
    isActive: boolean;
    avatarUrl?: string;
    phone?: string;
  };
}

export class AuthService {
  /**
   * Signup new user — also triggers verification email
   */
  async signup(
    name: string,
    email: string,
    password: string,
    phone?: string
  ): Promise<AuthResponse> {
    try {
      // Check if user exists
      const existingUser = await User.findOne({ email });
      if (existingUser) {
        throw new AppError('Email already registered', 409);
      }

      // Create user (phone is optional)
      const user = await User.create({
        name,
        email,
        password,
        phone: phone || '',
        role: 'user',
        isEmailVerified: false,
      });

      // Create patient profile
      await Patient.create({
        userId: user._id,
        allergies: [],
        medications: [],
      });

      // Send verification email (async — don't block signup completion)
      onboardingService.sendVerificationEmail(
        user._id.toString(),
        email,
        name
      ).catch((err) => logger.error('Failed to send verification email:', err));

      // Generate tokens
      const { accessToken, refreshToken, expiresAt } = this.generateTokens(
        user._id.toString(),
        user.role
      );

      logger.info(`User created: ${email}`);

      return {
        accessToken,
        refreshToken,
        expiresAt,
        user: {
          id: user._id.toString(),
          name: user.name,
          email: user.email,
          role: user.role,
          isEmailVerified: user.isEmailVerified,
          onboardingComplete: user.onboardingComplete,
          isActive: user.isActive,
          avatarUrl: user.avatarUrl,
          phone: user.phone,
        },
      };
    } catch (error) {
      if (error instanceof AppError) throw error;
      logger.error('Signup error:', error);
      throw new AppError('Failed to create user', 500);
    }
  }

  /**
   * Login user with email and password
   */
  async login(email: string, password: string): Promise<AuthResponse> {
    try {
      // Validate input
      if (!email || !password) {
        throw new AppError('Email and password are required', 400);
      }

      // Find user with password field
      const user = await User.findOne({ email: String(email).toLowerCase() }).select('+password');
      if (!user || !user.password) {
        throw new AppError('Invalid email or password', 401);
      }

      // Compare password
      const isPasswordValid = await user.comparePassword(password);
      if (!isPasswordValid) {
        throw new AppError('Invalid email or password', 401);
      }

      // Check if user is active
      if (!user.isActive) {
        throw new AppError('User account is deactivated', 403);
      }

      // Generate tokens
      const { accessToken, refreshToken, expiresAt } = this.generateTokens(
        user._id.toString(),
        user.role
      );

      logger.info(`User logged in: ${email}`);

      return {
        accessToken,
        refreshToken,
        expiresAt,
        user: {
          id: user._id.toString(),
          name: user.name,
          email: user.email,
          role: user.role,
          isEmailVerified: user.isEmailVerified,
          onboardingComplete: user.onboardingComplete,
          isActive: user.isActive,
          avatarUrl: user.avatarUrl,
          phone: user.phone,
        },
      };
    } catch (error) {
      if (error instanceof AppError) throw error;
      logger.error('Login error:', error);
      throw new AppError('Login failed', 500);
    }
  }

  /**
   * Handle Google OAuth authentication
   * Called after frontend verifies Google ID token server-side
   */
  async handleGoogleAuth(googleProfile: {
    googleId: string;
    email: string;
    name: string;
    avatarUrl?: string;
  }): Promise<AuthResponse> {
    try {
      const { googleId, email, name, avatarUrl } = googleProfile;

      // Check if user exists by Google ID
      let user = await User.findOne({ googleId });

      if (!user) {
        // Check if user exists by email (for account linking)
        user = await User.findOne({ email });

        if (user) {
          // Link Google ID to existing account
          user.googleId = googleId;
          if (avatarUrl && !user.avatarUrl) {
            user.avatarUrl = avatarUrl;
          }
          await user.save();
          logger.info(`Google ID linked to existing user: ${email}`);
        } else {
          // Create new user from Google profile
          user = await User.create({
            googleId,
            email,
            name,
            phone: '',
            avatarUrl,
            isEmailVerified: true, // Google emails are pre-verified
            role: 'user',
          });

          // Create patient profile
          await Patient.create({
            userId: user._id,
            allergies: [],
            medications: [],
          });

          logger.info(`New user created via Google: ${email}`);
        }
      }

      // Check if user is active
      if (!user.isActive) {
        throw new AppError('User account is deactivated', 403);
      }

      // Generate tokens
      const { accessToken, refreshToken, expiresAt } = this.generateTokens(
        user._id.toString(),
        user.role
      );

      return {
        accessToken,
        refreshToken,
        expiresAt,
        user: {
          id: user._id.toString(),
          name: user.name,
          email: user.email,
          role: user.role,
          isEmailVerified: user.isEmailVerified,
          onboardingComplete: user.onboardingComplete,
          isActive: user.isActive,
          avatarUrl: user.avatarUrl,
          phone: user.phone,
        },
      };
    } catch (error) {
      if (error instanceof AppError) throw error;
      logger.error('Google auth error:', error);
      throw new AppError('Google authentication failed', 500);
    }
  }

  /**
   * Generate JWT access and refresh tokens
   */
  generateTokens(
    userId: string,
    role: string
  ): {
    accessToken: string;
    refreshToken: string;
    expiresAt: string;
  } {
    const accessPayload = {
      userId,
      role,
      jti: randomBytes(16).toString('hex'),
    };

    const refreshPayload = {
      userId,
      role,
      jti: randomBytes(16).toString('hex'),
    };

    const accessToken = jwt.sign(accessPayload, config.jwt.secret, {
      expiresIn: config.jwt.accessExpiry,
    } as any);

    const refreshToken = jwt.sign(refreshPayload, config.jwt.refreshSecret, {
      expiresIn: config.jwt.refreshExpiry,
    } as any);

    const expiresAt = new Date(
      Date.now() + 30 * 60 * 1000 // 30 minutes from now
    ).toISOString();

    return { accessToken, refreshToken, expiresAt };
  }

  /**
   * Verify JWT token and return payload
   */
  verifyToken(token: string, type: 'access' | 'refresh' = 'access'): TokenPayload {
    try {
      const secret = type === 'access' ? config.jwt.secret : config.jwt.refreshSecret;
      const payload = jwt.verify(token, secret) as TokenPayload;
      return payload;
    } catch (error) {
      if (error instanceof jwt.TokenExpiredError) {
        throw new AppError('Token has expired', 401);
      }
      if (error instanceof jwt.JsonWebTokenError) {
        throw new AppError('Invalid token', 401);
      }
      throw new AppError('Token verification failed', 401);
    }
  }

  /**
   * Refresh access token using refresh token
   * Also returns a new refresh token (rotation)
   */
  async refreshToken(refreshToken: string): Promise<{
    accessToken: string;
    refreshToken: string;
    expiresAt: string;
  }> {
    try {
      // Check if token is blacklisted
      const isBlacklisted = await cacheService.get(`blacklist:${refreshToken}`);
      if (isBlacklisted) {
        throw new AppError('Token has been revoked', 401);
      }

      // Verify refresh token
      const payload = this.verifyToken(refreshToken, 'refresh');

      // Get user
      const user = await User.findById(payload.userId);
      if (!user) {
        throw new AppError('User not found', 404);
      }

      if (!user.isActive) {
        throw new AppError('User account is deactivated', 403);
      }

      // Blacklist old refresh token (rotation)
      const ttl = payload.exp - Math.floor(Date.now() / 1000);
      if (ttl > 0) {
        await cacheService.set(`blacklist:${refreshToken}`, 'true', ttl);
      }

      // Generate new tokens
      const tokens = this.generateTokens(user._id.toString(), user.role);

      logger.info(`Token refreshed for user: ${user.email}`);

      return tokens;
    } catch (error) {
      if (error instanceof AppError) throw error;
      logger.error('Token refresh error:', error);
      throw new AppError('Failed to refresh token', 500);
    }
  }

  /**
   * Logout user by blacklisting refresh token
   */
  async logout(refreshToken: string): Promise<void> {
    try {
      const payload = this.verifyToken(refreshToken, 'refresh');

      // Calculate TTL (remaining time until expiry)
      const ttl = payload.exp - Math.floor(Date.now() / 1000);

      // Add token to blacklist with TTL
      if (ttl > 0) {
        await cacheService.set(`blacklist:${refreshToken}`, 'true', ttl);
      }

      logger.info(`User logged out: ${payload.userId}`);
    } catch (error) {
      if (error instanceof AppError) throw error;
      logger.error('Logout error:', error);
      throw new AppError('Logout failed', 500);
    }
  }

  /**
   * Get user by ID
   */
  async getUserById(userId: string): Promise<IUser | null> {
    try {
      const user = await User.findById(userId);
      return user;
    } catch (error) {
      logger.error('Get user error:', error);
      throw new AppError('Failed to get user', 500);
    }
  }

  /**
   * Update user profile
   */
  async updateProfile(
    userId: string,
    updates: {
      name?: string;
      phone?: string;
      gender?: 'Male' | 'Female' | 'Others';
      age?: number;
      avatarUrl?: string;
    }
  ): Promise<IUser> {
    try {
      const user = await User.findByIdAndUpdate(userId, updates, {
        new: true,
        runValidators: true,
      });

      if (!user) {
        throw new AppError('User not found', 404);
      }

      logger.info(`User profile updated: ${user.email}`);
      return user;
    } catch (error) {
      if (error instanceof AppError) throw error;
      logger.error('Update profile error:', error);
      throw new AppError('Failed to update profile', 500);
    }
  }
}

export const authService = new AuthService();
