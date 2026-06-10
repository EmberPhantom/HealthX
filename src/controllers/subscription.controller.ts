import { Response } from 'express';
import UserSubscription from '../models/UserSubscription';
import MealPlan from '../models/MealPlan';
import Notification from '../models/Notification';
import { catchAsync } from '../utils/catchAsync';
import { AuthRequest } from '../middlewares/auth.middleware';
import { AppError } from '../utils/AppError';

/**
 * POST /subscriptions/subscribe
 * Subscribe to a meal plan
 */
export const subscribeToPlan = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { planId, billingPeriod } = req.body;

  if (!planId) {
    throw new AppError('Meal plan ID is required', 400);
  }

  const plan = await MealPlan.findById(planId);
  if (!plan) {
    throw new AppError('Meal plan not found', 404);
  }

  // Cancel any existing active subscription
  await UserSubscription.updateMany(
    { userId: req.user.userId, status: 'active' },
    { status: 'cancelled', endDate: new Date() }
  );

  // Set subscription duration (e.g. 30 days for monthly)
  const durationDays = billingPeriod === 'weekly' ? 7 : 30;
  const startDate = new Date();
  const endDate = new Date(Date.now() + durationDays * 24 * 60 * 60 * 1000);

  const subscription = await UserSubscription.create({
    userId: req.user.userId,
    planId,
    planName: plan.planName,
    price: plan.price,
    status: 'active',
    startDate,
    endDate,
    billingPeriod: billingPeriod || 'monthly',
  });

  // Create notifications
  await Notification.create({
    userId: req.user.userId,
    title: 'Plan Subscribed! 🥗',
    message: `You are now subscribed to the "${plan.planName}" plan.`,
    type: 'system',
    isRead: false,
  });

  res.status(201).json({
    statusCode: 201,
    status: 'success',
    message: 'Subscribed successfully',
    data: subscription,
  });
});

/**
 * POST /subscriptions/pause/:id
 * Pause a subscription
 */
export const pauseSubscription = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const subscription = await UserSubscription.findOneAndUpdate(
    { _id: req.params.id, userId: req.user.userId, status: 'active' },
    { status: 'paused' },
    { new: true }
  );

  if (!subscription) {
    throw new AppError('Active subscription not found to pause', 404);
  }

  await Notification.create({
    userId: req.user.userId,
    title: 'Subscription Paused ⏸️',
    message: `Your subscription to "${subscription.planName}" is paused.`,
    type: 'system',
    isRead: false,
  });

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    message: 'Subscription paused successfully',
    data: subscription,
  });
});

/**
 * POST /subscriptions/cancel/:id
 * Cancel a subscription
 */
export const cancelSubscription = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const subscription = await UserSubscription.findOneAndUpdate(
    { _id: req.params.id, userId: req.user.userId, status: { $in: ['active', 'paused'] } },
    { status: 'cancelled', endDate: new Date() },
    { new: true }
  );

  if (!subscription) {
    throw new AppError('Subscription not found or already ended', 404);
  }

  await Notification.create({
    userId: req.user.userId,
    title: 'Subscription Cancelled 🛑',
    message: `Your subscription to "${subscription.planName}" has been cancelled.`,
    type: 'system',
    isRead: false,
  });

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    message: 'Subscription cancelled successfully',
    data: subscription,
  });
});

/**
 * GET /subscriptions/me
 * Get user subscriptions
 */
export const getUserSubscriptions = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const subscriptions = await UserSubscription.find({ userId: req.user.userId }).sort({ createdAt: -1 });

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: subscriptions,
  });
});
