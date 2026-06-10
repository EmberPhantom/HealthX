import { Request, Response, NextFunction } from 'express';
import multer from 'multer';

// Setup filters captured from multer calls
let capturedImageFilter: any;
let capturedDocFilter: any;
const capturedSingleCalls: string[] = [];
const capturedArrayCalls: any[] = [];

jest.mock('multer', () => {
  const singleMock = jest.fn((name) => {
    capturedSingleCalls.push(name);
    return (req: any, res: any, next: any) => {
      next();
    };
  });
  singleMock.mockClear = () => {};
  singleMock.mockReset = () => {};

  const arrayMock = jest.fn((name, limit) => {
    capturedArrayCalls.push([name, limit]);
    return (req: any, res: any, next: any) => {
      next();
    };
  });
  arrayMock.mockClear = () => {};
  arrayMock.mockReset = () => {};

  const instance = {
    single: singleMock,
    array: arrayMock,
  };
  const mockMulter = (config: any) => {
    if (config && config.fileFilter) {
      if (config.limits && config.limits.fileSize === 2 * 1024 * 1024) {
        capturedImageFilter = config.fileFilter;
      } else if (config.limits && config.limits.fileSize === 10 * 1024 * 1024 && !config.limits.files) {
        capturedDocFilter = config.fileFilter;
      }
    }
    return instance;
  };
  mockMulter.memoryStorage = jest.fn();
  (mockMulter as any).MulterError = class MulterError extends Error {
    code: string;
    field?: string;
    constructor(code: string, field?: string) {
      super(code);
      this.code = code;
      this.field = field;
    }
  };
  return mockMulter;
});

// Import the middleware under test after the mock is established
import {
  uploadAvatar,
  uploadMultiple,
  uploadDocument,
  handleMulterError,
} from '../../../middlewares/upload.middleware';
import { AppError } from '../../../utils/AppError';

describe('Upload Middleware', () => {
  let req: any;
  let res: any;
  let next: any;

  beforeEach(() => {
    req = {
      file: undefined,
      files: undefined,
      headers: {},
    };
    res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
    };
    next = jest.fn();
  });

  describe('uploadAvatar middleware config', () => {
    it('should configure single file upload for field "file"', () => {
      expect(capturedSingleCalls).toContain('file');
    });

    it('should define an image file filter', () => {
      expect(capturedImageFilter).toBeDefined();
    });

    it('should accept image MIME types', (done) => {
      const file = { mimetype: 'image/jpeg' } as any;
      capturedImageFilter({}, file, (err: any, accepted: boolean) => {
        expect(err).toBeNull();
        expect(accepted).toBe(true);
        done();
      });
    });

    it('should reject non-image MIME types', (done) => {
      const file = { mimetype: 'application/pdf' } as any;
      capturedImageFilter({}, file, (err: any, accepted: boolean) => {
        expect(err).toBeInstanceOf(AppError);
        expect(err.statusCode).toBe(400);
        expect(accepted).toBeUndefined();
        done();
      });
    });
  });

  describe('uploadDocument middleware config', () => {
    it('should configure single file upload for field "document"', () => {
      expect(capturedSingleCalls).toContain('document');
    });

    it('should define a document file filter', () => {
      expect(capturedDocFilter).toBeDefined();
    });

    it('should accept document MIME types', (done) => {
      const file = { mimetype: 'application/pdf' } as any;
      capturedDocFilter({}, file, (err: any, accepted: boolean) => {
        expect(err).toBeNull();
        expect(accepted).toBe(true);
        done();
      });
    });

    it('should reject non-document MIME types', (done) => {
      const file = { mimetype: 'image/jpeg' } as any;
      capturedDocFilter({}, file, (err: any, accepted: boolean) => {
        expect(err).toBeInstanceOf(AppError);
        expect(err.statusCode).toBe(400);
        expect(accepted).toBeUndefined();
        done();
      });
    });
  });

  describe('handleMulterError', () => {
    it('should handle LIMIT_FILE_SIZE error with 413 Payload Too Large', () => {
      const err = new (multer as any).MulterError('LIMIT_FILE_SIZE', 'file');
      handleMulterError(err, req, res, next);
      expect(res.status).toHaveBeenCalledWith(413);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          statusCode: 413,
          message: expect.stringContaining('exceeds'),
        })
      );
    });

    it('should handle LIMIT_FILE_COUNT error with 400 Bad Request', () => {
      const err = new (multer as any).MulterError('LIMIT_FILE_COUNT', 'files');
      handleMulterError(err, req, res, next);
      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          statusCode: 400,
          message: expect.stringContaining('Too many files'),
        })
      );
    });

    it('should handle AppError and send its status code', () => {
      const err = new AppError('Invalid image format', 400);
      handleMulterError(err, req, res, next);
      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          statusCode: 400,
          message: 'Invalid image format',
        })
      );
    });

    it('should pass other errors to next()', () => {
      const err = new Error('Random system error');
      handleMulterError(err, req, res, next);
      expect(next).toHaveBeenCalledWith(err);
    });
  });
});
