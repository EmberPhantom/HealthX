import { Response } from 'express';

interface ApiResponse {
  statusCode: number;
  status: 'success' | 'fail' | 'error';
  message?: string;
  data: unknown;
}

export function sendSuccess(
  res: Response,
  data: unknown = null,
  message?: string,
  statusCode: number = 200
): void {
  const body: ApiResponse = {
    statusCode,
    status: 'success',
    data,
  };
  if (message) body.message = message;
  res.status(statusCode).json(body);
}

export function sendCreated(
  res: Response,
  data: unknown = null,
  message?: string
): void {
  sendSuccess(res, data, message, 201);
}
