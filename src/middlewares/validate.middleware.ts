import { Request, Response, NextFunction } from 'express';
import { ZodSchema, ZodError } from 'zod';
import logger from '../utils/logger';

/**
 * Validate request body using Zod schema
 */
export const validateRequest = (schema: ZodSchema) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    try {
      const validated = schema.parse(req.body);
      req.body = validated;
      next();
    } catch (error) {
      if (error instanceof ZodError) {
        const errors = error.issues.map((issue: any) => ({
          field: issue.path.join('.'),
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

      logger.error('Validation middleware error:', error);
      res.status(500).json({
        statusCode: 500,
        status: 'error',
        message: 'Validation failed',
      });
    }
  };
};

/**
 * Validate query parameters using Zod schema
 */
export const validateQuery = (schema: ZodSchema) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    try {
      const validated = schema.parse(req.query);
      req.query = validated as any;
      next();
    } catch (error) {
      if (error instanceof ZodError) {
        const errors = error.issues.map((issue: any) => ({
          field: issue.path.join('.'),
          message: issue.message,
        }));

        res.status(400).json({
          statusCode: 400,
          status: 'fail',
          message: 'Query validation error',
          errors,
          timestamp: new Date().toISOString(),
        });
        return;
      }

      logger.error('Query validation error:', error);
      res.status(500).json({
        statusCode: 500,
        status: 'error',
        message: 'Query validation failed',
      });
    }
  };
};
