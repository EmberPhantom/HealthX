import { Response } from 'express';
import { OAuth2Client } from 'google-auth-library';
import { authService } from '../services/auth.service';
import securityService from '../services/security.service';
import oauthService from '../services/oauth.service';
import { passwordResetService } from '../services/password-reset.service';
import { AppError } from '../utils/AppError';
import { catchAsync } from '../utils/catchAsync';
import { AuthRequest } from '../middlewares/auth.middleware';
import logger from '../utils/logger';
import { config } from '../config/config';
import { randomBytes } from 'crypto';

// Google OAuth2 client for ID token verification
const googleClient = new OAuth2Client(config.google.clientId);

/**
 * POST /auth/signup
 * Register new user
 */
export const signup = catchAsync(async (req: AuthRequest, res: Response) => {
  const { name, email, password, phone } = req.body;

  const result = await authService.signup(name, email, password, phone);

  res.status(201).json({
    statusCode: 201,
    status: 'success',
    message: 'User registered successfully. Please check your email to verify your account.',
    data: result,
  });
});

/**
 * POST /auth/login
 * Login with email and password
 */
export const login = catchAsync(async (req: AuthRequest, res: Response) => {
  const { email, password } = req.body;

  // Check if account is locked — FIX: destructure .locked property
  const lockStatus = await securityService.isAccountLocked(email);
  if (lockStatus.locked) {
    throw new AppError('Account is temporarily locked. Please try again later.', 429);
  }

  const result = await authService.login(email, password);

  // Clear failed attempts on successful login
  await securityService.clearFailedAttempts(email);

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    message: 'Login successful',
    data: result,
  });
});

/**
 * POST /auth/google
 * Google OAuth — verifies the Firebase/Google ID token sent by Flutter
 * Flutter uses google_sign_in + firebase_auth → gets idToken → sends here
 */
export const googleAuth = catchAsync(async (req: AuthRequest, res: Response) => {
  const { idToken } = req.body;

  if (!idToken) {
    throw new AppError('Google ID token is required', 400);
  }

  let googleId: string;
  let email: string;
  let name: string;
  let avatarUrl: string | undefined;

  try {
    // Verify the ID token with Google's servers
    const ticket = await googleClient.verifyIdToken({
      idToken,
      audience: config.google.clientId,
    });

    const payload = ticket.getPayload();
    if (!payload) {
      throw new AppError('Invalid Google token payload', 401);
    }

    googleId = payload.sub;
    email = payload.email || '';
    name = payload.name || payload.email || 'Google User';
    avatarUrl = payload.picture;

    if (!email) {
      throw new AppError('Google account does not have an email address', 400);
    }
  } catch (err: any) {
    // If it's already an AppError, rethrow it
    if (err instanceof AppError) throw err;
    logger.error('Google token verification failed:', err);
    throw new AppError('Invalid or expired Google token', 401);
  }

  // Find or create user
  const result = await authService.handleGoogleAuth({
    googleId,
    email,
    name,
    avatarUrl,
  });

  // Log the OAuth event
  await securityService.logSecurityEvent(
    result.user.id,
    'OAUTH_LOGIN',
    'auth',
    'POST',
    '/auth/google',
    200,
    req.ip || 'unknown',
    req.headers['user-agent'],
    { provider: 'google', email },
    true
  );

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    message: 'Google login successful',
    data: result,
  });
});

/**
 * POST /auth/refresh
 * Refresh access token using refresh token
 */
export const refreshToken = catchAsync(async (req: AuthRequest, res: Response) => {
  const { refreshToken } = req.body;

  if (!refreshToken) {
    throw new AppError('Refresh token is required', 400);
  }

  const result = await authService.refreshToken(refreshToken);

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    message: 'Token refreshed successfully',
    data: result,
  });
});

/**
 * POST /auth/logout
 * Logout user (blacklist refresh token)
 */
export const logout = catchAsync(async (req: AuthRequest, res: Response) => {
  const { refreshToken } = req.body;

  if (!refreshToken) {
    throw new AppError('Refresh token is required', 400);
  }

  await authService.logout(refreshToken);

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    message: 'Logout successful',
  });
});

/**
 * GET /auth/me
 * Get current authenticated user profile
 */
export const getCurrentUser = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const user = await authService.getUserById(req.user.userId);

  if (!user) {
    throw new AppError('User not found', 404);
  }

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    message: 'User profile retrieved successfully',
    data: {
      id: user._id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      gender: user.gender,
      age: user.age,
      avatarUrl: user.avatarUrl,
      role: user.role,
      isEmailVerified: user.isEmailVerified,
      onboardingComplete: user.onboardingComplete,
      isActive: user.isActive,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    },
  });
});

/**
 * PUT /auth/me
 * Update current user profile
 */
export const updateProfile = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { name, phone, gender, age } = req.body;

  const updatedUser = await authService.updateProfile(req.user.userId, {
    name,
    phone,
    gender,
    age,
  });

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    message: 'Profile updated successfully',
    data: {
      id: updatedUser._id,
      name: updatedUser.name,
      email: updatedUser.email,
      phone: updatedUser.phone,
      gender: updatedUser.gender,
      age: updatedUser.age,
      avatarUrl: updatedUser.avatarUrl,
      role: updatedUser.role,
      isEmailVerified: updatedUser.isEmailVerified,
      onboardingComplete: updatedUser.onboardingComplete,
    },
  });
});

/**
 * POST /auth/me/upload-picture
 * Upload profile picture
 */
export const uploadProfilePicture = catchAsync(
  async (req: AuthRequest, res: Response) => {
    if (!req.user) {
      throw new AppError('User not authenticated', 401);
    }

    if (!req.file) {
      throw new AppError('No file uploaded', 400);
    }

    // Import storage service
    const { default: storageService } = await import('../services/storage.service');

    // Save avatar
    const avatarUrl = await storageService.saveAvatar(req.file, req.user.userId);

    // Update user avatar URL in database
    const user = await authService.updateProfile(req.user.userId, {
      avatarUrl,
    });

    res.status(200).json({
      statusCode: 200,
      status: 'success',
      message: 'Profile picture uploaded successfully',
      data: {
        avatarUrl,
        user: {
          id: user._id,
          name: user.name,
          avatarUrl: user.avatarUrl,
        },
      },
    });
  }
);

/**
 * POST /auth/link
 * Link Google OAuth provider to existing account
 */
export const linkOAuthProvider = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { provider } = req.body;

  if (provider !== 'google') {
    throw new AppError('Only Google is supported as OAuth provider', 400);
  }

  // Generate a cryptographically secure state for OAuth CSRF protection
  const state = randomBytes(32).toString('hex');

  const authUrl = `https://accounts.google.com/o/oauth2/v2/auth?` +
    `client_id=${config.google.clientId}` +
    `&redirect_uri=${config.google.callbackUrl}` +
    `&response_type=code` +
    `&scope=openid+profile+email` +
    `&state=${state}`;

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    message: 'Redirect to Google OAuth for account linking',
    data: {
      authUrl,
      provider,
    },
  });
});

/**
 * POST /auth/unlink
 * Unlink Google OAuth provider from account
 */
export const unlinkOAuthProvider = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { provider } = req.body;

  if (provider !== 'google') {
    throw new AppError('Only Google is supported as OAuth provider', 400);
  }

  const updatedUser = await oauthService.unlinkOAuthProvider(
    req.user.userId,
    'google'
  );

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    message: 'Google has been unlinked from your account',
    data: {
      linkedProviders: oauthService.getLinkedProviders(updatedUser),
    },
  });
});

/**
 * POST /auth/forgot-password
 * Send password reset link
 */
export const forgotPassword = catchAsync(async (req: AuthRequest, res: Response) => {
  const { email } = req.body;
  
  await passwordResetService.requestReset(email);

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    message: 'If a user with this email exists, a password reset link has been sent.',
  });
});

/**
 * POST /auth/reset-password
 * Reset password using token
 */
export const resetPassword = catchAsync(async (req: AuthRequest, res: Response) => {
  const { token, password } = req.body;

  await passwordResetService.resetPassword(token, password);

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    message: 'Your password has been reset successfully.',
  });
});
