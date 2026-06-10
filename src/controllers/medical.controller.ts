import { Response } from 'express';
import VitalsLog from '../models/VitalsLog';
import GlucoseLog from '../models/GlucoseLog';
import InsulinLog from '../models/InsulinLog';
import MeasurementLog from '../models/MeasurementLog';
import { catchAsync } from '../utils/catchAsync';
import { AuthRequest } from '../middlewares/auth.middleware';
import { AppError } from '../utils/AppError';

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

  const logs = await VitalsLog.find({ userId: req.user.userId }).sort({ loggedAt: -1 });

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

  res.status(201).json({
    statusCode: 201,
    status: 'success',
    data: log,
  });
});

export const getGlucose = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const logs = await GlucoseLog.find({ userId: req.user.userId }).sort({ loggedAt: -1 });

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

  const logs = await InsulinLog.find({ userId: req.user.userId }).sort({ loggedAt: -1 });

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

  const logs = await MeasurementLog.find({ userId: req.user.userId }).sort({ loggedAt: -1 });

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
