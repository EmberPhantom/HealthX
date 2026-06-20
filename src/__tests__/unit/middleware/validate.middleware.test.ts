import { validateRequest, validateQuery } from '../../../middlewares/validate.middleware';
import { z } from 'zod';
import { Request, Response } from 'express';

describe('Validate Middleware Isolation Tests', () => {
  let mockReq: Partial<Request>;
  let mockRes: Partial<Response>;
  let nextFunction: jest.Mock;
  let jsonMock: jest.Mock;
  let statusMock: jest.Mock;

  const testSchema = z.object({
    email: z.string().email(),
    age: z.number().min(18),
  });

  beforeEach(() => {
    jsonMock = jest.fn();
    statusMock = jest.fn().mockReturnValue({ json: jsonMock });
    mockReq = {
      body: {},
      query: {},
    };
    mockRes = {
      status: statusMock,
    };
    nextFunction = jest.fn();
  });

  describe('validateRequest', () => {
    it('should call next() if request body is valid', () => {
      mockReq.body = { email: 'valid@example.com', age: 25 };
      const middleware = validateRequest(testSchema);

      middleware(mockReq as Request, mockRes as Response, nextFunction);

      expect(nextFunction).toHaveBeenCalled();
      expect(statusMock).not.toHaveBeenCalled();
    });

    it('should call next with AppError if request body is invalid', () => {
      mockReq.body = { email: 'not-an-email', age: 10 };
      const middleware = validateRequest(testSchema);

      middleware(mockReq as Request, mockRes as Response, nextFunction);

      expect(nextFunction).toHaveBeenCalledWith(
        expect.objectContaining({
          statusCode: 400,
          message: 'Validation error',
          details: expect.arrayContaining([
            expect.objectContaining({ field: expect.any(String) }),
          ]),
        })
      );
      expect(statusMock).not.toHaveBeenCalled();
    });
  });

  describe('validateQuery', () => {
    it('should call next() if query parameters are valid', () => {
      mockReq.query = { email: 'query@example.com', age: '30' as any }; // Zod will check it or fail, wait, we need to pass a number if age: z.number()
      mockReq.query = { email: 'query@example.com', age: 30 as any };
      const middleware = validateQuery(testSchema);

      middleware(mockReq as Request, mockRes as Response, nextFunction);

      expect(nextFunction).toHaveBeenCalled();
    });

    it('should call next with AppError if query parameters are invalid', () => {
      mockReq.query = { email: 'query@example.com', age: 15 as any };
      const middleware = validateQuery(testSchema);

      middleware(mockReq as Request, mockRes as Response, nextFunction);

      expect(nextFunction).toHaveBeenCalledWith(
        expect.objectContaining({
          statusCode: 400,
          message: 'Query validation error',
        })
      );
      expect(statusMock).not.toHaveBeenCalled();
    });
  });
});
