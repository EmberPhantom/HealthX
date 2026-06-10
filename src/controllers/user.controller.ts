import { Response } from 'express';
import { authService } from '../services/auth.service';
import User from '../models/User';
import Order from '../models/Order';
import Patient from '../models/Patient';
import WaterLog from '../models/WaterLog';
import SleepLog from '../models/SleepLog';
import StepLog from '../models/StepLog';
import MealLog from '../models/MealLog';
import Notification from '../models/Notification';
import AuditLog from '../models/AuditLog';
import LoginAttempt from '../models/LoginAttempt';
import { AppError } from '../utils/AppError';
import { catchAsync } from '../utils/catchAsync';
import { AuthRequest } from '../middlewares/auth.middleware';
import logger from '../utils/logger';

/**
 * GET /users/me/stats
 * Get dynamic stats for the user profile
 */
export const getStats = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const userId = req.user.userId;
  const user = await User.findById(userId);

  if (!user) {
    throw new AppError('User not found', 404);
  }

  // Aggregate stats
  const totalOrders = await Order.countDocuments({ userId });
  const favoritesCount = user.favorites.length;
  const rating = user.appRating || 4.8;
  const points = user.points || 0;

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: {
      totalOrders,
      favoritesCount,
      rating,
      points,
    },
  });
});

/**
 * POST /users/me/favorites/toggle
 * Toggle a menu item as favorite
 */
export const toggleFavorite = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { itemId } = req.body;
  if (!itemId) {
    throw new AppError('Item ID is required', 400);
  }

  const user = await User.findById(req.user.userId);
  if (!user) throw new AppError('User not found', 404);

  const index = user.favorites.indexOf(itemId as any);
  if (index > -1) {
    user.favorites.splice(index, 1);
  } else {
    user.favorites.push(itemId as any);
  }

  await user.save();

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: {
      favorites: user.favorites,
      isFavorite: index === -1,
    },
  });
});

/**
 * PUT /users/me/wellness-goals
 * Update wellness goals
 */
export const updateWellnessGoals = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { goals } = req.body;
  if (!Array.isArray(goals)) {
    throw new AppError('Goals must be an array of strings', 400);
  }

  const user = await User.findByIdAndUpdate(
    req.user.userId,
    { wellnessGoals: goals },
    { new: true }
  );

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: { wellnessGoals: user?.wellnessGoals },
  });
});

/**
 * POST /users/me/rating
 * Set app rating
 */
export const setAppRating = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { rating } = req.body;
  if (typeof rating !== 'number' || rating < 1 || rating > 5) {
    throw new AppError('Rating must be a number between 1 and 5', 400);
  }

  const user = await User.findByIdAndUpdate(
    req.user.userId,
    { appRating: rating },
    { new: true }
  );

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: { appRating: user?.appRating },
  });
});

/**
 * PATCH /users/me/points
 * Update user points (rewards)
 */
export const updatePoints = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { points } = req.body;
  if (typeof points !== 'number') {
    throw new AppError('Points must be a number', 400);
  }

  const user = await User.findByIdAndUpdate(
    req.user.userId,
    { $inc: { points: points } },
    { new: true }
  );

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: { totalPoints: user?.points },
  });
});

/**
 * GET /users/me
 * Get current user profile
 */
export const getProfile = catchAsync(async (req: AuthRequest, res: Response) => {
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
      isActive: user.isActive,
      onboardingComplete: user.onboardingComplete,
      favorites: user.favorites,
      wellnessGoals: user.wellnessGoals,
      appRating: user.appRating,
      points: user.points,
      settings: user.settings,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    },
  });
});

/**
 * PUT /users/me
 * Update user profile
 */
export const updateProfile = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { name, phone, gender, age, avatarUrl } = req.body;

  const updatedUser = await authService.updateProfile(req.user.userId, {
    name,
    phone,
    gender,
    age,
    avatarUrl,
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
      isActive: updatedUser.isActive,
      onboardingComplete: updatedUser.onboardingComplete,
    },
  });
});

/**
 * POST /users/me/upload-picture
 * Upload profile picture via multer (field: 'file')
 */
export const uploadPicture = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  if (!req.file) {
    throw new AppError('No file uploaded. Use field name "file" in the form data', 400);
  }

  // Import storage service lazily to avoid circular dependency issues
  const { default: storageService } = await import('../services/storage.service');

  const avatarUrl = await storageService.saveAvatar(req.file, req.user.userId);

  // Update user's avatarUrl in database
  const updatedUser = await authService.updateProfile(req.user.userId, { avatarUrl });

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    message: 'Profile picture uploaded successfully',
    data: {
      avatarUrl,
      user: {
        id: updatedUser._id,
        name: updatedUser.name,
        avatarUrl: updatedUser.avatarUrl,
      },
    },
  });
});

/**
 * DELETE /users/me
 * Delete account and all associated data (GDPR)
 */
export const deleteAccount = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) throw new AppError('User not authenticated', 401);

  const userId = req.user.userId;

  // First fetch the user to get their email address for login attempts cleanup
  const user = await User.findById(userId);
  const email = user?.email;

  // Hard delete all personal data (GDPR Article 17)
  await Promise.all([
    User.findByIdAndDelete(userId),
    Patient.findOneAndDelete({ userId }),
    WaterLog.deleteMany({ userId }),
    SleepLog.deleteMany({ userId }),
    StepLog.deleteMany({ userId }),
    MealLog.deleteMany({ userId }),
    Notification.deleteMany({ userId }),
    AuditLog.deleteMany({ userId }),
    ...(email ? [LoginAttempt.deleteMany({ email })] : []),
  ]);

  // Log the deletion (use a separate compliance log, not the deleted user's log)
  logger.info(`Account permanently deleted: userId=${userId}`);

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    message: 'Your account and all associated data have been permanently deleted.',
    data: null,
  });
});

/**
 * GET /users/me/settings
 * Get current user's settings (dailyWaterGoalMl, dailyStepGoal, reminderEnabled)
 */
export const getSettings = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const user = await User.findById(req.user.userId).select('settings');
  if (!user) {
    throw new AppError('User not found', 404);
  }

  // Provide defaults if not initialized
  const settings = user.settings || {
    dailyWaterGoalMl: 3000,
    dailyStepGoal: 8000,
    reminderEnabled: false,
  };

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: settings,
  });
});

/**
 * PUT /users/me/settings
 * Update current user's settings
 */
export const updateSettings = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { dailyWaterGoalMl, dailyStepGoal, reminderEnabled } = req.body;

  const updateFields: any = {};
  if (dailyWaterGoalMl !== undefined) updateFields['settings.dailyWaterGoalMl'] = dailyWaterGoalMl;
  if (dailyStepGoal !== undefined) updateFields['settings.dailyStepGoal'] = dailyStepGoal;
  if (reminderEnabled !== undefined) updateFields['settings.reminderEnabled'] = reminderEnabled;

  const user = await User.findByIdAndUpdate(
    req.user.userId,
    { $set: updateFields },
    { new: true, runValidators: true }
  ).select('settings');

  if (!user) {
    throw new AppError('User not found', 404);
  }

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: user.settings,
  });
});
