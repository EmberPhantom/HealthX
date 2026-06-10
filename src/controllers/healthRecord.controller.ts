import { Response } from 'express';
import HealthRecord from '../models/HealthRecord';
import { AuthRequest } from '../middlewares/auth.middleware';
import { catchAsync } from '../utils/catchAsync';
import { AppError } from '../utils/AppError';
import fileUploadService from '../services/storage.service';
import logger from '../utils/logger';

export const getHealthRecords = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { type, specialist } = req.query;
  const filter: any = { userId: req.user.userId };

  if (type) {
    filter.type = type;
  }
  if (specialist) {
    filter.specialist = new RegExp(specialist as string, 'i');
  }

  const records = await HealthRecord.find(filter).sort({ date: -1, createdAt: -1 });

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: records,
  });
});

export const createHealthRecord = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { name, type, date, specialist } = req.body;
  if (!name || !type || !date) {
    throw new AppError('Name, type, and date are required fields', 400);
  }

  const files = req.files as Express.Multer.File[];
  if (!files || files.length === 0) {
    throw new AppError('At least one file must be uploaded', 400);
  }

  const fileUrls: string[] = [];
  for (const file of files) {
    const fileUrl = await fileUploadService.saveHealthRecordFile(file, req.user.userId);
    fileUrls.push(fileUrl);
  }

  const record = await HealthRecord.create({
    userId: req.user.userId,
    name,
    type,
    date: new Date(date),
    fileUrls,
    specialist: specialist || '',
  });

  res.status(201).json({
    statusCode: 201,
    status: 'success',
    data: record,
  });
});

export const deleteHealthRecord = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const record = await HealthRecord.findOne({
    _id: req.params.id,
    userId: req.user.userId,
  });

  if (!record) {
    throw new AppError('Health record not found', 404);
  }

  // Delete all files from storage
  for (const url of record.fileUrls) {
    try {
      await fileUploadService.deleteFile(url);
    } catch (e) {
      logger.error(`Failed to delete record file: ${url}`, e);
    }
  }

  await record.deleteOne();

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: null,
  });
});
