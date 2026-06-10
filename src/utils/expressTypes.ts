import { Request, Response, NextFunction, RequestHandler } from 'express';

export type AsyncHandler = (req: Request, res: Response, next: NextFunction) => Promise<void>;

export function asHandler<P = any>(fn: (req: any, res: Response, next: NextFunction) => any): RequestHandler<P> {
  return (req, res, next) => {
    try {
      const result = fn(req, res, next);
      if (result instanceof Promise) {
        result.catch(next);
      }
    } catch (err) {
      next(err);
    }
  };
}
