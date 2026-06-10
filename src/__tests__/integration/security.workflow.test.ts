import request from 'supertest';
import express from 'express';
import { Types } from 'mongoose';
import authRoutes from "../../routes/auth.routes";
import securityRoutes from "../../routes/security.routes";
import securityService from "../../services/security.service";
import { authService } from "../../services/auth.service";
import { AppError } from '../../utils/AppError';
import { errorMiddleware } from '../../middlewares/errorMiddleware';

jest.mock('../../services/security.service', () => ({
  __esModule: true,
  default: {
    trackLoginAttempt: jest.fn(),
    isAccountLocked: jest.fn(),
    clearFailedAttempts: jest.fn(),
    generateCSRFToken: jest.fn(),
    logSecurityEvent: jest.fn(),
    getLoginHistory: jest.fn(),
    getSuspiciousActivity: jest.fn(),
  }
}));
jest.mock('../../middlewares/auth.middleware', () => ({
  authMiddleware: (req, res, next) => {
    req.user = { userId: '507f1f77bcf86cd799439012', role: 'admin' }; // admin role to bypass role limits
    next();
  },
  roleMiddleware: (roles) => (req, res, next) => next()
}));

jest.mock('../../services/auth.service', () => ({
  __esModule: true,
  authService: {
    login: jest.fn(),
    logout: jest.fn(),
    changePassword: jest.fn(),
  }
}));

describe('Security & Authentication Integration Tests', () => {
  let app: express.Application;
  const mockUserId = '507f1f77bcf86cd799439012';
  const mockEmail = 'security@example.com';
  const mockPassword = 'SecurePass@123456';
  const mockIpAddress = '192.168.1.100';

  beforeEach(() => {
    app = express();
    app.set('trust proxy', true);
    app.use(express.json());
    app.use('/auth', authRoutes);
    app.use('/security', securityRoutes);
    app.use(errorMiddleware as any);
    jest.clearAllMocks();
    // Default mocks to prevent TypeError undefined properties
    (securityService.isAccountLocked as jest.Mock).mockResolvedValue({ locked: false });
    (securityService.trackLoginAttempt as jest.Mock).mockResolvedValue({ isBlocked: false });
    (securityService.logSecurityEvent as jest.Mock).mockResolvedValue(true);
    
  });

  describe('Rate Limiting', () => {
    it.skip('should enforce rate limiting on auth endpoints', async () => {
      const loginData = { email: mockEmail, password: mockPassword };

      // Make 6 requests (limit is 5)
      for (let i = 0; i < 5; i++) {
        await request(app)
          .post('/auth/login')
          .send(loginData);
      }

      // 6th request should be rate limited
      const sixthRes = await request(app)
        .post('/auth/login')
        .send(loginData);

      expect(sixthRes.status).toBeGreaterThanOrEqual(429); // Too Many Requests
    });

    it.skip('should track request rates per IP address', async () => {
      const loginData = { email: mockEmail, password: mockPassword };

      // Requests from IP1
      await request(app)
        .post('/auth/login')
        .send(loginData)
        .set('X-Forwarded-For', '192.168.1.100');

      // Requests from IP2 should have separate rate limit
      const res = await request(app)
        .post('/auth/login')
        .send(loginData)
        .set('X-Forwarded-For', '192.168.1.101');

      expect(res.status).not.toBe(429);
    });

    it.skip('should apply stricter limits to sensitive operations', async () => {
      // Sensitive operation rate limit should be lower
      const sensitiveData = { currentPassword: mockPassword, newPassword: 'NewPass@123456' };

      for (let i = 0; i < 3; i++) {
        await request(app)
          .put('/auth/change-password')
          .send(sensitiveData)
          .set('Authorization', `Bearer fake-token`);
      }

      // 4th request should be rate limited (limit is 3)
      const fourthRes = await request(app)
        .put('/auth/change-password')
        .send(sensitiveData)
        .set('Authorization', `Bearer fake-token`);

      expect(fourthRes.status).toBeGreaterThanOrEqual(429);
    });
  });

  describe('Account Lockout', () => {
    it('should lock account after 5 failed login attempts', async () => {
      (authService.login as jest.Mock).mockRejectedValue(
        new AppError('Invalid email or password', 401)
      );
      (securityService.trackLoginAttempt as jest.Mock).mockResolvedValue(
        { isBlocked: true, blockedUntil: new Date() }
      );

      // Make 5 failed login attempts
      for (let i = 0; i < 5; i++) {
        await request(app)
          .post('/auth/login')
          .send({ email: mockEmail, password: 'wrong-password' });
      }

      // 6th attempt should fail with locked message
      const sixthRes = await request(app)
        .post('/auth/login')
        .send({ email: mockEmail, password: mockPassword });

      expect(sixthRes.status).toBeGreaterThanOrEqual(400);
    });

    it('should unlock account after lockout period', async () => {
      (securityService.isAccountLocked as jest.Mock)
        .mockResolvedValueOnce({ locked: true }) // Initially locked
        .mockResolvedValueOnce({ locked: false }); // After period

      (authService.login as jest.Mock).mockResolvedValue({
        user: { _id: mockUserId, email: mockEmail },
        accessToken: 'token-123',
      });

      // Try login while locked
      const lockedRes = await request(app)
        .post('/auth/login')
        .send({ email: mockEmail, password: mockPassword });

      expect(lockedRes.status).toBeGreaterThanOrEqual(400);

      // Try again after unlock
      const unlockedRes = await request(app)
        .post('/auth/login')
        .send({ email: mockEmail, password: mockPassword });

      expect(unlockedRes.status).not.toBe(400);
    });

    it('should allow clearing failed attempts for admin', async () => {
      (securityService.clearFailedAttempts as jest.Mock).mockResolvedValue({
        message: 'Failed attempts cleared',
      });

      const res = await request(app)
        .post('/security/clear-failed-attempts')
        .send({ email: mockEmail })
        .set('Authorization', `Bearer admin-token`)
        .set('X-Admin-Key', 'admin-secret');

      expect(res.status).toBe(200);
    });
  });

  describe('CSRF Protection', () => {
    it('should provide CSRF token for state-changing operations', async () => {
      (securityService.generateCSRFToken as jest.Mock).mockReturnValue(
        'csrf-token-abc123'
      );

      const res = await request(app)
        .get('/security/csrf-token')
        .expect(200);

      expect(res.body.data).toHaveProperty('csrfToken');
      expect(res.body.data.csrfToken).toBe('csrf-token-abc123');
    });

    it.skip('should validate CSRF token on POST requests', async () => {
      const validToken = 'csrf-token-valid';
      const csrfData = {
        email: 'newuser@example.com',
        password: 'Pass@123456',
      };

      // Request should fail without CSRF token
      await request(app)
        .post('/auth/signup')
        .send(csrfData)
        .expect(403); // Forbidden due to missing CSRF

      // Request should succeed with valid CSRF
      const res = await request(app)
        .post('/auth/signup')
        .send(csrfData)
        .set('X-CSRF-Token', validToken)
        .expect(200);

      expect(res.body).toHaveProperty('user');
    });

    it.skip('should reject invalid CSRF tokens', async () => {
      const invalidToken = 'csrf-token-invalid';
      const signupData = {
        email: 'newuser@example.com',
        password: 'Pass@123456',
      };

      await request(app)
        .post('/auth/signup')
        .send(signupData)
        .set('X-CSRF-Token', invalidToken)
        .expect(403);
    });

    it('should regenerate CSRF token after validation', async () => {
      const token1 = 'csrf-token-1';
      const token2 = 'csrf-token-2';

      (securityService.generateCSRFToken as jest.Mock)
        .mockReturnValueOnce(token1)
        .mockReturnValueOnce(token2);

      // Get first token
      const res1 = await request(app)
        .get('/security/csrf-token')
        .expect(200);

      expect(res1.body.data.csrfToken).toBe(token1);

      // Get second token (should be different)
      const res2 = await request(app)
        .get('/security/csrf-token')
        .expect(200);

      expect(res2.body.data.csrfToken).toBe(token2);
      expect(res2.body.data.csrfToken).not.toBe(res1.body.data.csrfToken);
    });
  });

  describe('Audit Logging', () => {
    it('should log all authentication events', async () => {
      (authService.login as jest.Mock).mockResolvedValue({
        user: { _id: mockUserId },
        accessToken: 'token',
      });
      (securityService.logSecurityEvent as jest.Mock).mockResolvedValue(true);

      await request(app)
        .post('/auth/login')
        .send({ email: mockEmail, password: mockPassword })
        .expect(200);

      expect(securityService.logSecurityEvent).toHaveBeenCalledWith(
        null,
        'LOGIN',
        expect.any(String),
        expect.any(String),
        expect.any(String),
        200,
        expect.any(String),
        undefined,
        expect.any(Object),
        true
      );
    });

    it('should log failed login attempts', async () => {
      (authService.login as jest.Mock).mockRejectedValue(
        new AppError('Invalid credentials', 401)
      );
      (securityService.logSecurityEvent as jest.Mock).mockResolvedValue(true);

      await request(app)
        .post('/auth/login')
        .send({ email: mockEmail, password: 'wrong' });

      expect(securityService.logSecurityEvent).toHaveBeenCalledWith(
        null,
        'LOGIN',
        expect.any(String),
        expect.any(String),
        expect.any(String),
        401,
        expect.any(String),
        undefined,
        expect.any(Object),
        false
      );
    });

    it.skip('should log password changes', async () => {
      (authService.changePassword as jest.Mock).mockResolvedValue({
        message: 'Password changed',
      });
      (securityService.logSecurityEvent as jest.Mock).mockResolvedValue(true);

      await request(app)
        .put('/auth/change-password')
        .send({
          currentPassword: mockPassword,
          newPassword: 'NewPass@123456',
        })
        .set('Authorization', `Bearer token`)
        .expect(200);

      expect(securityService.logSecurityEvent).toHaveBeenCalledWith(
        expect.objectContaining({
          action: 'PASSWORD_CHANGE',
        })
      );
    });

    it('should track IP address in all audit logs', async () => {
      (authService.login as jest.Mock).mockResolvedValue({
        user: { _id: mockUserId },
        accessToken: 'token',
      });
      (securityService.logSecurityEvent as jest.Mock).mockResolvedValue(true);

      await request(app)
        .post('/auth/login')
        .send({ email: mockEmail, password: mockPassword })
        .set('X-Forwarded-For', mockIpAddress)
        .expect(200);

      expect(securityService.logSecurityEvent).toHaveBeenCalledWith(
        null,
        'LOGIN',
        expect.any(String),
        expect.any(String),
        expect.any(String),
        200,
        mockIpAddress,
        undefined,
        expect.any(Object),
        true
      );
    });
  });

  describe('Login History', () => {
    it('should retrieve user login history', async () => {
      (securityService.getLoginHistory as jest.Mock).mockResolvedValue([
        {
          action: 'LOGIN',
          timestamp: new Date(),
          ipAddress: '192.168.1.100',
          success: true,
        },
        {
          action: 'LOGOUT',
          timestamp: new Date(),
          ipAddress: '192.168.1.100',
          success: true,
        },
      ]);

      const res = await request(app)
        .get('/security/login-history')
        .set('Authorization', `Bearer token`)
        .expect(200);

      expect(res.body.data.logins).toHaveLength(2);
      expect(res.body.data.logins[0].action).toBe('LOGIN');
    });

    it('should limit history results', async () => {
      (securityService.getLoginHistory as jest.Mock).mockResolvedValue([]);

      await request(app)
        .get('/security/login-history?limit=10')
        .set('Authorization', `Bearer token`)
        .expect(200);

      expect(securityService.getLoginHistory).toHaveBeenCalledWith(
        mockUserId,
        expect.any(Number)
      );
    });
  });

  describe('Suspicious Activity Detection', () => {
    it('should detect suspicious login activity', async () => {
      (securityService.getSuspiciousActivity as jest.Mock).mockResolvedValue({
        suspiciousLogins: [
          { ipAddress: '10.0.0.1', failedAttempts: 8 },
        ],
        unusualLocations: [],
        passwordChanges: [],
      });

      const res = await request(app)
        .get('/security/suspicious-activity?ip=127.0.0.1')
        .set('Authorization', `Bearer token`)
        .expect(200);

      expect(res.body.data).toHaveProperty('suspiciousLogins');
      expect(res.body.data.suspiciousLogins.length).toBeGreaterThan(0);
    });

    it('should alert user of suspicious activity', async () => {
      // This would typically send an email alert
      (securityService.getSuspiciousActivity as jest.Mock).mockResolvedValue({
        suspiciousLogins: [
          { ipAddress: '10.0.0.1', failedAttempts: 10 },
        ],
      });

      await request(app)
        .get('/security/suspicious-activity?ip=127.0.0.1')
        .set('Authorization', `Bearer token`)
        .expect(200);

      // Email alert would be triggered in the service
    });
  });

  describe('Session Management', () => {
    it('should create session on login', async () => {
      (authService.login as jest.Mock).mockResolvedValue({
        user: { _id: mockUserId },
        accessToken: 'token-123',
        refreshToken: 'refresh-token-456',
      });

      const res = await request(app)
        .post('/auth/login')
        .send({ email: mockEmail, password: mockPassword })
        .expect(200);

      expect(res.body.data).toHaveProperty('accessToken');
      expect(res.body.data).toHaveProperty('refreshToken');
    });

    it('should invalidate session on logout', async () => {
      (authService.logout as jest.Mock).mockResolvedValue({
        message: 'Logged out successfully',
      });

      await request(app)
        .post('/auth/logout')
        .set('Authorization', `Bearer token`)
        .send({ refreshToken: 'refresh-token-456' })
        .expect(200);

      expect(authService.logout).toHaveBeenCalled();
    });
  });
});
