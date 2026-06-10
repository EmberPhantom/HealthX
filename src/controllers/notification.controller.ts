import { Response } from 'express';
import Notification from '../models/Notification';
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
