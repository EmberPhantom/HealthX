import { errorMiddleware } from '../../../middlewares/errorMiddleware';
import { AppError } from '../../../utils/AppError';
import { ZodError } from 'zod';
import { Request, Response } from 'express';

describe('Error Middleware Tests', () => {
  let mockReq: Partial<Request>;
  let mockRes: Partial<Response>;
  let nextFunction: jest.Mock;

  beforeEach(() => {
    mockReq = {
      path: '/api/v1/test',
      method: 'GET',
    };
    mockRes = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
    };
    nextFunction = jest.fn();
  });

  it('should format ZodError validation issues into 400 response', () => {
    const zodError = new ZodError([
      {
        code: 'invalid_type',
        expected: 'string',
        received: 'number',
        path: ['email'],
        message: 'Expected string, received number',
      },
    ]);

    errorMiddleware(zodError, mockReq as Request, mockRes as Response, nextFunction);

    expect(mockRes.status).toHaveBeenCalledWith(400);
    expect(mockRes.json).toHaveBeenCalledWith(
      expect.objectContaining({
        statusCode: 400,
        status: 'fail',
        message: 'Validation error',
        errors: expect.arrayContaining([
          expect.objectContaining({
            path: 'email',
            message: 'Expected string, received number',
          }),
        ]),
      })
    );
  });

  it('should format operational AppError into correct status code and message', () => {
    const appError = new AppError('Conflict data exists', 409);

    errorMiddleware(appError, mockReq as Request, mockRes as Response, nextFunction);

    expect(mockRes.status).toHaveBeenCalledWith(409);
    expect(mockRes.json).toHaveBeenCalledWith(
      expect.objectContaining({
        statusCode: 409,
        status: 'fail',
        message: 'Conflict data exists',
      })
    );
  });
});
