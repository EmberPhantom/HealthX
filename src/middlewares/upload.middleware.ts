import multer, { StorageEngine, Multer } from 'multer';
import path from 'path';
import { AppError } from '../utils/AppError';

/**
 * Memory storage for multer (files stored in memory, not disk)
 * Useful for image processing with sharp before saving to disk
 */
const memoryStorage = multer.memoryStorage();

/**
 * File filter for images
 */
const imageFileFilter = (
  req: any,
  file: Express.Multer.File,
  callback: (error: Error | null, acceptFile?: boolean) => void
) => {
  const allowedMimes = ['image/jpeg', 'image/png', 'image/webp'];

  if (!allowedMimes.includes(file.mimetype)) {
    return callback(
      new AppError(
        `Invalid file type. Only ${allowedMimes.join(', ')} are allowed`,
        400
      )
    );
  }

  callback(null, true);
};

/**
 * File filter for documents
 */
const documentFileFilter = (
  req: any,
  file: Express.Multer.File,
  callback: (error: Error | null, acceptFile?: boolean) => void
) => {
  const allowedMimes = [
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  ];

  if (!allowedMimes.includes(file.mimetype)) {
    return callback(
      new AppError(
        `Invalid file type. Only ${allowedMimes.join(', ')} are allowed`,
        400
      )
    );
  }

  callback(null, true);
};

/**
 * Avatar upload middleware
 */
export const uploadAvatar = multer({
  storage: memoryStorage,
  fileFilter: imageFileFilter,
  limits: {
    fileSize: 2 * 1024 * 1024, // 2MB
  },
}).single('file');

/**
 * General image upload middleware (for 'image' field)
 */
export const uploadImage = multer({
  storage: memoryStorage,
  fileFilter: imageFileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB
  },
}).single('image');

/**
 * Multiple files upload middleware
 */
export const uploadMultiple = multer({
  storage: memoryStorage,
  fileFilter: imageFileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB
    files: 10,
  },
}).array('files', 10);

/**
 * Document upload middleware
 */
export const uploadDocument = multer({
  storage: memoryStorage,
  fileFilter: documentFileFilter,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB
  },
}).single('document');

/**
 * File filter for health records (accepts images and PDFs)
 */
const healthRecordFileFilter = (
  req: any,
  file: Express.Multer.File,
  callback: (error: Error | null, acceptFile?: boolean) => void
) => {
  const allowedMimes = [
    'image/jpeg',
    'image/png',
    'image/webp',
    'application/pdf',
  ];

  if (!allowedMimes.includes(file.mimetype)) {
    return callback(
      new AppError(
        `Invalid file type. Only ${allowedMimes.join(', ')} are allowed`,
        400
      )
    );
  }

  callback(null, true);
};

/**
 * Health record files upload middleware (up to 10 files)
 */
export const uploadHealthRecord = multer({
  storage: memoryStorage,
  fileFilter: healthRecordFileFilter,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB
    files: 10,
  },
}).array('files', 10);

/**
 * Error handling middleware for multer errors
 */
export const handleMulterError = (
  err: any,
  req: any,
  res: any,
  next: any
) => {
  if (err instanceof multer.MulterError) {
    if (err.code === 'LIMIT_FILE_SIZE') {
      return res.status(413).json({
        statusCode: 413,
        status: 'fail',
        message: 'File size exceeds the limit',
      });
    }
    if (err.code === 'LIMIT_FILE_COUNT') {
      return res.status(400).json({
        statusCode: 400,
        status: 'fail',
        message: 'Too many files uploaded',
      });
    }
    if (err.code === 'LIMIT_FIELD_COUNT') {
      return res.status(400).json({
        statusCode: 400,
        status: 'fail',
        message: 'Too many fields in form',
      });
    }
  }

  if (err instanceof AppError) {
    return res.status(err.statusCode).json({
      statusCode: err.statusCode,
      status: 'fail',
      message: err.message,
    });
  }

  next(err);
};
