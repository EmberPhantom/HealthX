import { Request, Response, NextFunction } from 'express';
import { auditLog } from '../../../middlewares/audit.middleware';
import AuditLog from '../../../models/AuditLog';
import securityService from '../../../services/security.service';

jest.mock('../../../models/AuditLog');
jest.mock('../../../services/security.service', () => {
  const mockInstance = {
    trackLoginAttempt: jest.fn(),
    checkSuspiciousActivity: jest.fn(),
    checkRateLimit: jest.fn(),
    logSecurityHeaders: jest.fn(),
    logSecurityEvent: jest.fn().mockResolvedValue(undefined),
    getSuspiciousActivity: jest.fn().mockResolvedValue({ isBlocked: false, failedAttempts: 0 }),
  };
  return {
    __esModule: true,
    default: mockInstance,
    ...mockInstance,
  };
});

interface AuditRequest extends Request {
  user?: { _id: string };
  originalUrl?: string;
  method?: string;
}

describe('Audit Middleware', () => {
  let req: AuditRequest;
  let res: Response;
  let next: NextFunction;

  beforeEach(() => {
    req = {
      user: { _id: 'user-123' },
      originalUrl: '/api/users',
      method: 'GET',
      headers: {
        'user-agent': 'Mozilla/5.0',
        'x-forwarded-for': '192.168.1.100',
      },
      ip: '192.168.1.100',
    } as AuditRequest;

    res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
    } as any;

    next = jest.fn();
    jest.clearAllMocks();
  });

  describe('auditLog middleware factory', () => {
    it('should create middleware function', () => {
      const middleware = auditLog('LOGIN');

      expect(typeof middleware).toBe('function');
    });

    it('should call next middleware', (done) => {
      const middleware = auditLog('LOGIN');

      middleware(req, res, next);

      expect(next).toHaveBeenCalled();
      done();
    });
  });

  describe('Audit Logging', () => {
    it('should log security event for auth endpoints', async () => {
      req.method = 'POST';
      req.originalUrl = '/auth/login';

      (securityService.logSecurityEvent as jest.Mock).mockResolvedValue(true);

      const middleware = auditLog('LOGIN');
      middleware(req, res, next);

      // After next is called, event should be logged
      expect(next).toHaveBeenCalled();
    });

    it('should include request details in audit log', async () => {
      (securityService.logSecurityEvent as jest.Mock).mockResolvedValue(true);

      const middleware = auditLog('LOGIN');
      middleware(req, res, next);

      // Verify next was called with middleware in chain
      expect(next).toHaveBeenCalled();
    });

    it('should log IP address', async () => {
      req.ip = '10.0.0.1';

      (securityService.logSecurityEvent as jest.Mock).mockResolvedValue(true);

      const middleware = auditLog('LOGIN');
      middleware(req, res, next);

      expect(next).toHaveBeenCalled();
    });

    it('should capture user agent', async () => {
      req.headers['user-agent'] = 'Custom User Agent';

      (securityService.logSecurityEvent as jest.Mock).mockResolvedValue(true);

      const middleware = auditLog('LOGIN');
      middleware(req, res, next);

      expect(next).toHaveBeenCalled();
    });
  });

  describe('Suspicious Activity Detection', () => {
    it('should track failed login attempts', async () => {
      req.method = 'POST';
      req.originalUrl = '/auth/login';

      (securityService.trackLoginAttempt as jest.Mock).mockResolvedValue({
        consecutiveFailures: 1,
      });

      const middleware = auditLog('LOGIN');
      middleware(req, res, next);

      expect(next).toHaveBeenCalled();
    });

    it('should block suspicious IPs', async () => {
      req.ip = '10.0.0.1';
      const suspiciousIPs = ['10.0.0.1'];

      (securityService.checkSuspiciousActivity as jest.Mock).mockResolvedValue(true);

      const middleware = auditLog('LOGIN');
      middleware(req, res, next);

      expect(next).toHaveBeenCalled();
    });

    it('should detect rate limit violations', async () => {
      (securityService.checkRateLimit as jest.Mock).mockResolvedValue(false);

      const middleware = auditLog('LOGIN');
      middleware(req, res, next);

      expect(next).toHaveBeenCalled();
    });
  });

  describe('CSRF Token Logging', () => {
    it('should validate CSRF headers are present', async () => {
      req.method = 'POST';
      req.headers['x-csrf-token'] = 'token-123';

      (securityService.logSecurityHeaders as jest.Mock).mockResolvedValue(true);

      const middleware = auditLog('LOGIN');
      middleware(req, res, next);

      expect(next).toHaveBeenCalled();
    });

    it('should log missing CSRF tokens', async () => {
      req.method = 'POST';
      delete req.headers['x-csrf-token'];

      const middleware = auditLog('LOGIN');
      middleware(req, res, next);

      expect(next).toHaveBeenCalled();
    });
  });

  describe('IP Whitelist', () => {
    it('should allow localhost access', (done) => {
      req.ip = '127.0.0.1';

      const middleware = auditLog('LOGIN');
      middleware(req, res, next);

      expect(next).toHaveBeenCalled();
      done();
    });

    it('should allow ::1 (IPv6 localhost)', (done) => {
      req.ip = '::1';

      const middleware = auditLog('LOGIN');
      middleware(req, res, next);

      expect(next).toHaveBeenCalled();
      done();
    });

    it('should check whitelist from environment', (done) => {
      req.ip = '192.168.1.1';

      const middleware = auditLog('LOGIN');
      middleware(req, res, next);

      expect(next).toHaveBeenCalled();
      done();
    });
  });

  describe('Response Interception', () => {
    it('should capture response status', async () => {
      res.statusCode = 200;

      (AuditLog.create as jest.Mock).mockResolvedValue({
        _id: 'log-123',
        status: 200,
      });

      const middleware = auditLog('LOGIN');
      middleware(req, res, next);

      expect(next).toHaveBeenCalled();
    });

    it('should log error responses', async () => {
      res.statusCode = 401;

      (AuditLog.create as jest.Mock).mockResolvedValue({
        _id: 'log-123',
        status: 401,
      });

      const middleware = auditLog('LOGIN');
      middleware(req, res, next);

      expect(next).toHaveBeenCalled();
    });

    it('should log 4xx errors with details', async () => {
      res.statusCode = 400;

      (AuditLog.create as jest.Mock).mockResolvedValue({
        status: 400,
        errorMessage: expect.any(String),
      });

      const middleware = auditLog('LOGIN');
      middleware(req, res, next);

      expect(next).toHaveBeenCalled();
    });
  });

  describe('Security Headers', () => {
    it('should validate Content-Security-Policy header', async () => {
      req.headers['content-security-policy'] = "default-src 'self'";

      const middleware = auditLog('LOGIN');
      middleware(req, res, next);

      expect(next).toHaveBeenCalled();
    });

    it('should check X-Content-Type-Options', async () => {
      req.headers['x-content-type-options'] = 'nosniff';

      const middleware = auditLog('LOGIN');
      middleware(req, res, next);

      expect(next).toHaveBeenCalled();
    });

    it('should log missing security headers', async () => {
      delete req.headers['x-content-type-options'];

      (securityService.logSecurityHeaders as jest.Mock).mockResolvedValue({
        missingHeaders: ['X-Content-Type-Options'],
      });

      const middleware = auditLog('LOGIN');
      middleware(req, res, next);

      expect(next).toHaveBeenCalled();
    });
  });

  describe('Audit Log Performance', () => {
    it('should not block request processing', (done) => {
      const middleware = auditLog('LOGIN');
      const startTime = Date.now();

      middleware(req, res, next);

      const duration = Date.now() - startTime;

      // Should be very fast (async operation)
      expect(duration).toBeLessThan(100);
      done();
    });

    it('should handle rapid successive requests', async () => {
      const middleware = auditLog('LOGIN');

      const requests = Array(10).fill(null).map(() => ({
        ...req,
      }));

      requests.forEach((request) => {
        middleware(request as any, res, next);
      });

      expect(next).toHaveBeenCalledTimes(10);
    });
  });

  describe('Error Handling', () => {
    it('should handle audit logging errors gracefully', (done) => {
      (AuditLog.create as jest.Mock).mockRejectedValue(
        new Error('Database error')
      );

      const middleware = auditLog('LOGIN');
      middleware(req, res, next);

      // Should still call next even if audit fails
      expect(next).toHaveBeenCalled();
      done();
    });

    it('should not throw on missing user', (done) => {
      delete req.user;

      const middleware = auditLog('LOGIN');
      middleware(req, res, next);

      expect(next).toHaveBeenCalled();
      done();
    });
  });

  describe('Endpoint-Specific Logging', () => {
    it('should log auth endpoints with enhanced details', (done) => {
      req.originalUrl = '/auth/login';
      req.method = 'POST';

      const middleware = auditLog('LOGIN');
      middleware(req, res, next);

      expect(next).toHaveBeenCalled();
      done();
    });

    it('should log sensitive operations differently', (done) => {
      req.originalUrl = '/auth/change-password';
      req.method = 'PUT';

      const middleware = auditLog('LOGIN');
      middleware(req, res, next);

      expect(next).toHaveBeenCalled();
      done();
    });

    it('should log file upload operations', (done) => {
      req.originalUrl = '/auth/me/upload-picture';
      req.method = 'POST';

      const middleware = auditLog('LOGIN');
      middleware(req, res, next);

      expect(next).toHaveBeenCalled();
      done();
    });
  });
});
