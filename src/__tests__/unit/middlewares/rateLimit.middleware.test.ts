import { Request, Response, NextFunction } from 'express';
import { createRateLimiter, authRateLimiter, apiRateLimiter } from '../../../middlewares/rateLimit.middleware';
import securityService from '../../../services/security.service';

jest.mock('../../../services/security.service');

interface RateLimitRequest extends Request {
  user?: { _id: string; userId?: string };
  ip?: string;
}

describe('Rate Limiting Middleware', () => {
  let req: RateLimitRequest;
  let res: Response;
  let next: NextFunction;

  beforeEach(() => {
    req = {
      method: 'POST',
      headers: {
        'x-forwarded-for': '192.168.1.100',
        'x-test-rate-limit': 'true',
      },
      ip: '192.168.1.100',
    } as RateLimitRequest;

    res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
      set: jest.fn().mockReturnThis(),
      setHeader: jest.fn().mockReturnThis(),
    } as any;

    next = jest.fn();
    jest.clearAllMocks();
  });

  describe('createRateLimiter', () => {
    it('should create rate limiter with correct parameters', () => {
      const limiter = createRateLimiter({
        windowMs: 15 * 60 * 1000,
        max: 5,
        keyGenerator: (req: any) => req.ip || 'unknown',
      });

      expect(limiter).toBeDefined();
      expect(typeof limiter).toBe('function');
    });
  });

  describe('authRateLimiter (5 requests per 15 minutes)', () => {
    it('should allow request within limit', async () => {
      (securityService.checkRateLimit as jest.Mock).mockResolvedValue({
        allowed: true,
        remaining: 3,
        resetAt: new Date(Date.now() + 15 * 60 * 1000),
      });

      await authRateLimiter(req, res, next);

      expect(next).toHaveBeenCalled();
      expect(res.status).not.toHaveBeenCalledWith(429);
    });

    it('should block request exceeding limit', async () => {
      (securityService.checkRateLimit as jest.Mock).mockResolvedValue({
        allowed: false,
        remaining: 0,
        resetAt: new Date(Date.now() + 15 * 60 * 1000),
      });

      await authRateLimiter(req, res, next);

      expect(res.status).toHaveBeenCalledWith(429);
      expect(next).not.toHaveBeenCalled();
    });

    it('should rate limit per IP address + email', async () => {
      (securityService.checkRateLimit as jest.Mock).mockResolvedValue({
        allowed: true,
        remaining: 4,
        resetAt: new Date(),
      });

      req.body = { email: 'test@example.com' };
      await authRateLimiter(req, res, next);

      expect(securityService.checkRateLimit).toHaveBeenCalledWith(
        '192.168.1.100_test@example.com',
        5,
        15
      );
    });
  });

  describe('apiRateLimiter (100 requests per 15 minutes)', () => {
    it('should allow request within limit', async () => {
      (securityService.checkRateLimit as jest.Mock).mockResolvedValue({
        allowed: true,
        remaining: 50,
        resetAt: new Date(),
      });

      await apiRateLimiter(req, res, next);

      expect(next).toHaveBeenCalled();
    });
  });

  describe('Rate Limit Response Headers', () => {
    it('should set rate limit headers on response', async () => {
      (securityService.checkRateLimit as jest.Mock).mockResolvedValue({
        allowed: true,
        remaining: 3,
        resetAt: new Date(Date.now() + 15 * 60 * 1000),
      });

      await authRateLimiter(req, res, next);

      expect(res.set).toHaveBeenCalledWith(
        expect.objectContaining({
          'X-RateLimit-Limit': 5,
          'X-RateLimit-Remaining': 3,
          'X-RateLimit-Reset': expect.any(Number),
        })
      );
    });
  });

  describe('Error Handling', () => {
    it('should handle database errors gracefully', async () => {
      (securityService.checkRateLimit as jest.Mock).mockRejectedValue(
        new Error('Database error')
      );

      await authRateLimiter(req, res, next);

      expect(res.status).toHaveBeenCalledWith(500);
    });
  });
});
