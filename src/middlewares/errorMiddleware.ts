import { Request, Response, NextFunction } from 'express';
import { AppError } from '../utils/AppError';
import { config } from '../config/config';
import logger from '../utils/logger';
import { ZodError } from 'zod';

export const errorMiddleware = (
  err: any,
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  const statusCode = err.statusCode || err.status || 500;
  const status = err.status || 'error';

  // Log error details
  logger.error({
    message: err.message,
    statusCode,
    status,
    path: req.path,
    method: req.method,
    stack: err.stack,
  });

  // Handle Zod validation errors
  if (err instanceof ZodError) {
    const errors = err.issues.map((issue: any) => ({
      path: issue.path.join('.'),
      message: issue.message,
      code: issue.code,
    }));

    res.status(400).json({
      statusCode: 400,
      status: 'fail',
      message: 'Validation error',
      errors,
      timestamp: new Date().toISOString(),
    });
    return;
  }

  // Handle AppError (operational errors)
  if (err instanceof AppError && err.isOperational) {
    const body: Record<string, any> = {
      statusCode: err.statusCode,
      status: 'fail',
      message: err.message,
      timestamp: new Date().toISOString(),
    };
    if (err.details) {
      body.errors = err.details;
    }
    res.status(err.statusCode).json(body);
    return;
  }

  // Development response
  if (config.env === 'development') {
    res.status(statusCode).json({
      statusCode,
      status,
      message: err.message,
      error: err,
      stack: err.stack,
      timestamp: new Date().toISOString(),
    });
    return;
  }

  // Production response (generic message)
  res.status(500).json({
    statusCode: 500,
    status: 'error',
    message:
      statusCode === 500
        ? 'Internal server error. Please try again later.'
        : err.message || 'Something went wrong',
    timestamp: new Date().toISOString(),
  });
};