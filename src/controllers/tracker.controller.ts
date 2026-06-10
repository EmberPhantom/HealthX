import { Response } from 'express';
import WaterLog from '../models/WaterLog';
import SleepLog from '../models/SleepLog';
import StepLog from '../models/StepLog';
import { catchAsync } from '../utils/catchAsync';
import { AuthRequest } from '../middlewares/auth.middleware';
import { AppError } from '../utils/AppError';

// ── Water Tracking ──────────────────────────────────────────────────────────

/**
 * POST /trackers/water
 * Log water intake
 */
export const logWater = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { amount, date } = req.body;

  const waterLog = await WaterLog.create({
    userId: req.user.userId,
    amount,
    loggedAt: date ? new Date(date) : new Date(),
  });

  res.status(201).json({
    statusCode: 201,
    status: 'success',
    data: waterLog,
  });
});

/**
 * GET /trackers/water
 * Get water intake logs for a date range
 */
export const getWaterLogs = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { startDate, endDate } = req.query;

  const query: any = { userId: req.user.userId };

  if (startDate || endDate) {
    query.loggedAt = {};
    if (startDate) query.loggedAt.$gte = new Date(startDate as string);
    if (endDate) query.loggedAt.$lte = new Date(endDate as string);
  }

  const logs = await WaterLog.find(query).sort({ loggedAt: 1 });

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: logs,
  });
});

// ── Sleep Tracking ──────────────────────────────────────────────────────────

/**
 * POST /trackers/sleep
 * Log sleep session
 */
export const logSleep = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { bedtime, wakeTime, dateKey } = req.body;

  const sleepLog = await SleepLog.findOneAndUpdate(
    { userId: req.user.userId, dateKey },
    { bedtime, wakeTime },
    { upsert: true, new: true, runValidators: true }
  );

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: sleepLog,
  });
});

/**
 * GET /trackers/sleep
 * Get sleep logs
 */
export const getSleepLogs = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const logs = await SleepLog.find({ userId: req.user.userId })
    .sort({ dateKey: -1 })
    .limit(30);

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: logs,
  });
});

// ── Step Tracking ───────────────────────────────────────────────────────────

/**
 * POST /trackers/steps
 * Log daily steps
 */
export const logSteps = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { steps, dateKey } = req.body;

  const stepLog = await StepLog.findOneAndUpdate(
    { userId: req.user.userId, dateKey },
    { steps },
    { upsert: true, new: true, runValidators: true }
  );

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: stepLog,
  });
});

/**
 * GET /trackers/steps
 * Get step logs
 */
export const getStepLogs = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { startDate, endDate } = req.query;
  const query: any = { userId: req.user.userId };

  if (startDate || endDate) {
    query.dateKey = {};
    if (startDate) query.dateKey.$gte = startDate;
    if (endDate) query.dateKey.$lte = endDate;
  }

  const logs = await StepLog.find(query).sort({ dateKey: 1 });

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: logs,
  });
});
