import securityService from '../../../services/security.service';
import AuditLog from '../../../models/AuditLog';
import LoginAttempt from '../../../models/LoginAttempt';
import { Types } from 'mongoose';

jest.mock('../../../models/AuditLog');
jest.mock('../../../models/LoginAttempt');

describe('SecurityService', () => {
  const mockUserId = new Types.ObjectId().toString();
  const mockEmail = 'test@example.com';
  const mockIpAddress = '192.168.1.100';
  const mockUserAgent = 'Mozilla/5.0';

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('CSRF Token Management', () => {
    describe('generateCSRFToken', () => {
      it('should generate a valid CSRF token', async () => {
        const token = securityService.generateCSRFToken();

        expect(token).toBeDefined();
        expect(typeof token).toBe('string');
        expect(token.length).toBeGreaterThan(0);
      });

      it('should generate unique tokens on each call', async () => {
        const token1 = securityService.generateCSRFToken();
        const token2 = securityService.generateCSRFToken();

        expect(token1).not.toBe(token2);
      });
    });
  });

  describe('Login Attempt Tracking', () => {
    describe('trackLoginAttempt', () => {
      it('should track successful login attempt', async () => {
        (LoginAttempt.create as jest.Mock).mockResolvedValue({
          _id: new Types.ObjectId(),
          userId: mockUserId,
          email: mockEmail,
          success: true,
        });
        (LoginAttempt.updateMany as jest.Mock).mockResolvedValue({ modifiedCount: 1 });

        await securityService.trackLoginAttempt(
          mockEmail,
          mockIpAddress,
          true,
          mockUserAgent,
          mockUserId
        );

        expect(LoginAttempt.create).toHaveBeenCalledWith(
          expect.objectContaining({
            userId: mockUserId,
            email: mockEmail,
            ipAddress: mockIpAddress,
            userAgent: mockUserAgent,
            success: true,
          })
        );
      });

      it('should track failed login attempt and check lockout', async () => {
        (LoginAttempt.create as jest.Mock).mockResolvedValue({
          _id: new Types.ObjectId(),
          userId: mockUserId,
          email: mockEmail,
          success: false,
        });
        (LoginAttempt.countDocuments as jest.Mock).mockResolvedValue(2);

        const result = await securityService.trackLoginAttempt(
          mockEmail,
          mockIpAddress,
          false,
          mockUserAgent,
          mockUserId
        );

        expect(LoginAttempt.create).toHaveBeenCalled();
        expect(LoginAttempt.countDocuments).toHaveBeenCalled();
        expect(result.isBlocked).toBe(false);
      });

      it('should lock account after 5 failed attempts', async () => {
        (LoginAttempt.create as jest.Mock).mockResolvedValue({
          _id: new Types.ObjectId(),
          userId: mockUserId,
          email: mockEmail,
          success: false,
        });
        (LoginAttempt.countDocuments as jest.Mock).mockResolvedValue(5);
        (LoginAttempt.updateMany as jest.Mock).mockResolvedValue({ modifiedCount: 5 });
        (AuditLog.create as jest.Mock).mockResolvedValue({});

        const result = await securityService.trackLoginAttempt(
          mockEmail,
          mockIpAddress,
          false,
          mockUserAgent,
          mockUserId
        );

        expect(LoginAttempt.create).toHaveBeenCalled();
        expect(LoginAttempt.updateMany).toHaveBeenCalledWith(
          { email: mockEmail },
          expect.objectContaining({
            isBlocked: true,
            blockedUntil: expect.any(Date),
          })
        );
        expect(result.isBlocked).toBe(true);
      });
    });

    describe('isAccountLocked', () => {
      it('should return false for non-existent account', async () => {
        (LoginAttempt.findOne as jest.Mock).mockResolvedValue(null);

        const result = await securityService.isAccountLocked(mockEmail);

        expect(result.locked).toBe(false);
      });

      it('should return false for account without active blocks', async () => {
        (LoginAttempt.findOne as jest.Mock).mockResolvedValue(null);

        const result = await securityService.isAccountLocked(mockEmail);

        expect(result.locked).toBe(false);
      });

      it('should return true for locked account', async () => {
        (LoginAttempt.findOne as jest.Mock).mockResolvedValue({
          email: mockEmail,
          isBlocked: true,
          blockedUntil: new Date(Date.now() + 10 * 60 * 1000),
        });

        const result = await securityService.isAccountLocked(mockEmail);

        expect(result.locked).toBe(true);
        expect(result.blockedUntil).toBeDefined();
      });

      it('should unlock account after lockout period expires', async () => {
        const expiredLock = {
          email: mockEmail,
          isBlocked: true,
          blockedUntil: new Date(Date.now() - 1000), // in the past
        };

        (LoginAttempt.findOne as jest.Mock).mockResolvedValue(expiredLock);
        (LoginAttempt.updateMany as jest.Mock).mockResolvedValue({ modifiedCount: 1 });

        const result = await securityService.isAccountLocked(mockEmail);

        expect(LoginAttempt.updateMany).toHaveBeenCalledWith(
          { email: mockEmail },
          { isBlocked: false, blockedUntil: null }
        );
        expect(result.locked).toBe(false);
      });
    });
  });

  describe('Rate Limiting', () => {
    describe('checkRateLimit', () => {
      beforeEach(() => {
        (securityService as any).rateLimitInMemoryStore.clear();
      });

      it('should allow requests within rate limit', async () => {
        let result = await securityService.checkRateLimit(
          mockIpAddress,
          5, // limit
          15 // windowMinutes
        );

        expect(result.allowed).toBe(true);
        expect(result.remaining).toBe(4);
      });

      it('should block requests exceeding rate limit', async () => {
        // Use up all 5 allowed requests
        for (let i = 0; i < 5; i++) {
          await securityService.checkRateLimit(mockIpAddress, 5, 15);
        }

        const result = await securityService.checkRateLimit(
          mockIpAddress,
          5, // limit
          15 // windowMinutes
        );

        expect(result.allowed).toBe(false);
        expect(result.remaining).toBe(0);
      });
    });
  });

  describe('Audit Logging', () => {
    describe('logSecurityEvent', () => {
      it('should log security event successfully', async () => {
        (AuditLog.create as jest.Mock).mockResolvedValue({
          _id: new Types.ObjectId(),
          userId: mockUserId,
          action: 'LOGIN',
          ipAddress: mockIpAddress,
        });

        await securityService.logSecurityEvent(
          mockUserId,
          'LOGIN',
          'auth',
          'POST',
          '/auth/login',
          200,
          mockIpAddress,
          mockUserAgent,
          undefined,
          true
        );

        expect(AuditLog.create).toHaveBeenCalledWith(
          expect.objectContaining({
            userId: mockUserId,
            action: 'LOGIN',
            ipAddress: mockIpAddress,
          })
        );
      });
    });

    describe('getLoginHistory', () => {
      it('should retrieve login history for user', async () => {
        const mockLogins = [
          {
            userId: mockUserId,
            action: 'LOGIN',
            timestamp: new Date(),
            ipAddress: mockIpAddress,
            userAgent: mockUserAgent,
          },
        ];

        (AuditLog.find as jest.Mock).mockResolvedValue(mockLogins);

        const history = await securityService.getLoginHistory(mockUserId, 10);

        expect(history).toHaveLength(1);
        expect(history[0].action).toBe('LOGIN');
      });

      it('should return empty array if no history found', async () => {
        (AuditLog.find as jest.Mock).mockResolvedValue([]);

        const history = await securityService.getLoginHistory(mockUserId, 10);

        expect(history).toEqual([]);
      });
    });

    describe('getSuspiciousActivity', () => {
      it('should detect multiple failed logins from same IP', async () => {
        (LoginAttempt.countDocuments as jest.Mock).mockResolvedValue(3);
        (LoginAttempt.findOne as jest.Mock).mockResolvedValue({
          attemptedAt: new Date(),
          isBlocked: true,
          blockedUntil: new Date(Date.now() + 5 * 60 * 1000),
          email: mockEmail,
        });

        const suspicious = await securityService.getSuspiciousActivity(mockIpAddress);

        expect(suspicious.failedAttempts).toBe(3);
        expect(suspicious.isBlocked).toBe(true);
      });
    });
  });

  describe('clearFailedAttempts', () => {
    it('should clear failed attempts for user', async () => {
      (LoginAttempt.deleteMany as jest.Mock).mockResolvedValue({
        deletedCount: 1,
      });

      await securityService.clearFailedAttempts(mockEmail);

      expect(LoginAttempt.deleteMany).toHaveBeenCalledWith({
        email: mockEmail,
        success: false,
      });
    });
  });
});
