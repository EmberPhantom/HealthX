import { createRateLimiter } from '../../../middlewares/rateLimit.middleware';
import securityService from '../../../services/security.service';
import { Request, Response } from 'express';

jest.mock('../../../services/security.service');

describe('Rate Limit Middleware Tests', () => {
  let mockReq: Partial<Request>;
  let mockRes: Partial<Response>;
  let nextFunction: jest.Mock;
  const mockSetHeader = jest.fn();

  beforeEach(() => {
    mockReq = {
      ip: '127.0.0.1',
      headers: {
        'x-test-rate-limit': 'true', // force it to run in test environment
      },
    };
    mockRes = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
      setHeader: mockSetHeader,
      set: mockSetHeader,
    };
    nextFunction = jest.fn();
    jest.clearAllMocks();
  });

  it('should call next if rate limit is not exceeded', async () => {
    const mockCheckRateLimit = securityService.checkRateLimit as jest.Mock;
    mockCheckRateLimit.mockResolvedValue({
      allowed: true,
      remaining: 5,
      resetAt: new Date(Date.now() + 1000 * 60),
    });

    const limiter = createRateLimiter({ maxRequests: 10, windowMinutes: 1 });
    await limiter(mockReq as Request, mockRes as Response, nextFunction);

    expect(nextFunction).toHaveBeenCalled();
    expect(mockSetHeader).toHaveBeenCalledWith(
      expect.objectContaining({
        'X-RateLimit-Limit': 10,
        'X-RateLimit-Remaining': 5,
        'X-RateLimit-Reset': expect.any(Number),
      })
    );
  });

  it('should return 429 status code if rate limit is exceeded', async () => {
    const mockCheckRateLimit = securityService.checkRateLimit as jest.Mock;
    const resetTime = new Date(Date.now() + 1000 * 60);
    mockCheckRateLimit.mockResolvedValue({
      allowed: false,
      remaining: 0,
      resetAt: resetTime,
    });

    const limiter = createRateLimiter({ maxRequests: 10, windowMinutes: 1 });
    await limiter(mockReq as Request, mockRes as Response, nextFunction);

    expect(nextFunction).not.toHaveBeenCalled();
    expect(mockRes.status).toHaveBeenCalledWith(429);
    expect(mockRes.json).toHaveBeenCalledWith(
      expect.objectContaining({
        status: 'fail',
        message: expect.stringContaining('Rate limit exceeded'),
      })
    );
  });
});
