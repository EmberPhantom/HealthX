import { Response } from 'express';
import Notification from '../models/Notification';
import User from '../models/User';
import notificationDispatcher from '../services/notification.service';
import { catchAsync } from '../utils/catchAsync';
import { AuthRequest } from '../middlewares/auth.middleware';
import { AppError } from '../utils/AppError';

/**
 * GET /notifications
 * Get all notifications for the current user
 */
export const getNotifications = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const notifications = await Notification.find({ userId: req.user.userId })
    .sort({ createdAt: -1 })
    .limit(50);

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: notifications,
  });
});

/**
 * GET /notifications/unread-count
 * Get unread notification count for badge display
 */
export const getUnreadCount = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const count = await notificationDispatcher.getUnreadCount(req.user.userId);

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: { count },
  });
});

/**
 * PATCH /notifications/:id/read
 * Mark a notification as read
 */
export const markAsRead = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const notification = await Notification.findOneAndUpdate(
    { _id: req.params.id, userId: req.user.userId },
    { isRead: true },
    { new: true }
  );

  if (!notification) {
    throw new AppError('Notification not found', 404);
  }

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: notification,
  });
});

/**
 * PATCH /notifications/read-all
 * Mark all notifications as read
 */
export const markAllRead = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  await notificationDispatcher.markAllRead(req.user.userId);

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    message: 'All notifications marked as read',
    data: null,
  });
});

/**
 * DELETE /notifications/:id
 * Delete a notification
 */
export const deleteNotification = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const result = await Notification.deleteOne({
    _id: req.params.id,
    userId: req.user.userId
  });

  if (result.deletedCount === 0) {
    throw new AppError('Notification not found', 404);
  }

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    message: 'Notification deleted successfully',
    data: null,
  });
});

/**
 * POST /users/me/fcm-token
 * Register or refresh the FCM device token for the authenticated user
 */
export const registerFcmToken = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { token } = req.body;
  if (!token || typeof token !== 'string') {
    throw new AppError('FCM token is required', 400);
  }

  await User.findByIdAndUpdate(req.user.userId, { fcmToken: token });

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    message: 'FCM token registered',
    data: null,
  });
});

/**
 * DELETE /users/me/fcm-token
 * Remove FCM token on logout so we stop sending pushes to a signed-out device
 */
export const removeFcmToken = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  await User.findByIdAndUpdate(req.user.userId, { $unset: { fcmToken: '' } });

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    message: 'FCM token removed',
    data: null,
  });
});
