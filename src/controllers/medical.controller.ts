import { Response } from 'express';
import { FilterQuery } from 'mongoose';
import VitalsLog, { IVitalsLog } from '../models/VitalsLog';
import GlucoseLog, { IGlucoseLog } from '../models/GlucoseLog';
import InsulinLog, { IInsulinLog } from '../models/InsulinLog';
import MeasurementLog, { IMeasurementLog } from '../models/MeasurementLog';
import AIHealthProfile from '../models/AIHealthProfile';
import aiHealthService from '../services/ai-health.service';
import { catchAsync } from '../utils/catchAsync';
import { AuthRequest } from '../middlewares/auth.middleware';
import { AppError } from '../utils/AppError';
import notificationDispatcher from '../services/notification.service';

// ── Vitals Log ───────────────────────────────────────────────────────────────

export const logVitals = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { date, time, bp, pulse, temperature, weight, spo2, exerciseMins } = req.body;

  const log = await VitalsLog.create({
    userId: req.user.userId,
    date,
    time,
    bp,
    pulse,
    temperature,
    weight,
    spo2,
    exerciseMins,
  });

  // Push health alert for abnormal vitals
  if (spo2 !== undefined && Number(spo2) < 94) {
    notificationDispatcher.dispatch({
      userId: req.user.userId,
      title: '⚠️ Low Oxygen Saturation',
      body: `Your SpO₂ reading of ${spo2}% is below safe levels. Please seek medical attention.`,
      type: 'error',
      category: 'health',
      data: { type: 'health_alert', metric: 'spo2' },
    }).catch(() => {});
  }
  if (bp && typeof bp === 'object') {
    const systolic = Number((bp as any).systolic);
    if (!isNaN(systolic) && systolic > 180) {
      notificationDispatcher.dispatch({
        userId: req.user.userId,
        title: '⚠️ High Blood Pressure Alert',
        body: `Your systolic blood pressure of ${systolic} mmHg is dangerously high. Please consult your doctor.`,
        type: 'error',
        category: 'health',
        data: { type: 'health_alert', metric: 'bp' },
      }).catch(() => {});
    }
  }

  res.status(201).json({
    statusCode: 201,
    status: 'success',
    data: log,
  });
});

export const getVitals = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { page, limit } = req.query;
  const p = parseInt(page as string, 10) || 1;
  const l = parseInt(limit as string, 10) || 20;
  const skip = (p - 1) * l;

  const logs = await VitalsLog.find({ userId: req.user.userId })
    .sort({ loggedAt: -1 })
    .skip(skip)
    .limit(l);

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: logs,
  });
});

export const deleteVitals = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const log = await VitalsLog.findOneAndDelete({ _id: req.params.id, userId: req.user.userId });
  if (!log) {
    throw new AppError('Vitals log not found', 404);
  }

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: null,
  });
});

// ── Glucose Log ──────────────────────────────────────────────────────────────

export const logGlucose = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { level, readingType, note, loggedAt } = req.body;

  const log = await GlucoseLog.create({
    userId: req.user.userId,
    level,
    readingType,
    note,
    loggedAt: loggedAt ? new Date(loggedAt) : new Date(),
  });

  // AI inline comment — rule-based lookup, no extra API call
  const aiProfile = await AIHealthProfile.findOne({ userId: req.user.userId });
  const inlineComment = aiHealthService.getGlucoseInlineComment(aiProfile, Number(level), String(readingType));

  // Increment log counter and potentially trigger re-analysis in background
  aiHealthService.onLogEntry(req.user.userId, 'glucose_log').catch(() => {});

  // Push health alert if glucose is critically abnormal
  const glucoseLevel = Number(level);
  if (glucoseLevel < 70 || glucoseLevel > 250) {
    const isHigh = glucoseLevel > 250;
    notificationDispatcher.dispatch({
      userId: req.user.userId,
      title: isHigh ? '⚠️ High Blood Sugar Alert' : '⚠️ Low Blood Sugar Alert',
      body: isHigh
        ? `Your glucose reading of ${glucoseLevel} mg/dL is critically high. Please consult your doctor.`
        : `Your glucose reading of ${glucoseLevel} mg/dL is critically low. Eat something immediately.`,
      type: 'error',
      category: 'health',
      data: { type: 'health_alert', metric: 'glucose' },
    }).catch(() => {});
  }

  res.status(201).json({
    statusCode: 201,
    status: 'success',
    data: log,
    inlineComment,   // null if user is not diabetic or has no AI profile
  });
});

export const getGlucose = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { page, limit } = req.query;
  const p = parseInt(page as string, 10) || 1;
  const l = parseInt(limit as string, 10) || 20;
  const skip = (p - 1) * l;

  const logs = await GlucoseLog.find({ userId: req.user.userId })
    .sort({ loggedAt: -1 })
    .skip(skip)
    .limit(l);

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: logs,
  });
});

export const deleteGlucose = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const log = await GlucoseLog.findOneAndDelete({ _id: req.params.id, userId: req.user.userId });
  if (!log) {
    throw new AppError('Glucose log not found', 404);
  }

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: null,
  });
});

// ── Insulin Log ──────────────────────────────────────────────────────────────

export const logInsulin = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { dose, insulinType, injectionSite, mealContext, note, loggedAt } = req.body;

  const log = await InsulinLog.create({
    userId: req.user.userId,
    dose,
    insulinType,
    injectionSite,
    mealContext,
    note,
    loggedAt: loggedAt ? new Date(loggedAt) : new Date(),
  });

  res.status(201).json({
    statusCode: 201,
    status: 'success',
    data: log,
  });
});

export const getInsulin = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { page, limit } = req.query;
  const p = parseInt(page as string, 10) || 1;
  const l = parseInt(limit as string, 10) || 20;
  const skip = (p - 1) * l;

  const logs = await InsulinLog.find({ userId: req.user.userId })
    .sort({ loggedAt: -1 })
    .skip(skip)
    .limit(l);

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: logs,
  });
});

export const deleteInsulin = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const log = await InsulinLog.findOneAndDelete({ _id: req.params.id, userId: req.user.userId });
  if (!log) {
    throw new AppError('Insulin log not found', 404);
  }

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: null,
  });
});

// ── Measurement Log ──────────────────────────────────────────────────────────

export const logMeasurement = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { weight, height, chest, waist, hips, bodyFatPercent, loggedAt } = req.body;

  let bmi: number | undefined;
  if (weight && height) {
    const heightInMeters = height / 100;
    bmi = weight / (heightInMeters * heightInMeters);
  }

  const log = await MeasurementLog.create({
    userId: req.user.userId,
    weight,
    height,
    bmi,
    chest,
    waist,
    hips,
    bodyFatPercent,
    loggedAt: loggedAt ? new Date(loggedAt) : new Date(),
  });

  res.status(201).json({
    statusCode: 201,
    status: 'success',
    data: log,
  });
});

export const getMeasurements = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { page, limit } = req.query;
  const p = parseInt(page as string, 10) || 1;
  const l = parseInt(limit as string, 10) || 20;
  const skip = (p - 1) * l;

  const logs = await MeasurementLog.find({ userId: req.user.userId })
    .sort({ loggedAt: -1 })
    .skip(skip)
    .limit(l);

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: logs,
  });
});

export const deleteMeasurement = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const log = await MeasurementLog.findOneAndDelete({ _id: req.params.id, userId: req.user.userId });
  if (!log) {
    throw new AppError('Measurement log not found', 404);
  }

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: null,
  });
});
