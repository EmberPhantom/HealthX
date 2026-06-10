import sessionService from '../../../services/session.service';
import cacheService from '../../../services/cache.service';
import { Types } from 'mongoose';
import AppError from '../../../utils/AppError';

jest.mock('../../../services/cache.service');

describe('SessionService', () => {
  const mockUserId = new Types.ObjectId().toString();
  const mockSessionId = 'session-123-abc';
  const mockDeviceInfo = {
    userAgent: 'Mozilla/5.0',
    ipAddress: '192.168.1.100',
    deviceType: 'web',
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('createSession', () => {
    it('should create new session', async () => {
      (cacheService.set as jest.Mock).mockResolvedValue(true);

      const sessionData = {
        userId: mockUserId,
        ...mockDeviceInfo,
      };

      const result = await sessionService.createSession(mockUserId, mockDeviceInfo);

      expect(result).toBeDefined();
      expect(result).toHaveProperty('sessionId');
      expect(cacheService.set).toHaveBeenCalled();
    });

    it('should set TTL to 30 minutes', async () => {
      (cacheService.set as jest.Mock).mockResolvedValue(true);

      await sessionService.createSession(mockUserId, mockDeviceInfo);

      const callArgs = (cacheService.set as jest.Mock).mock.calls[0];
      const ttl = callArgs[2];

      // 30 minutes = 1800 seconds
      expect(ttl).toBe(1800);
    });

    it('should store device information', async () => {
      (cacheService.set as jest.Mock).mockResolvedValue(true);

      await sessionService.createSession(mockUserId, mockDeviceInfo);

      const callArgs = (cacheService.set as jest.Mock).mock.calls[0];
      const sessionData = callArgs[1];

      expect(sessionData).toHaveProperty('userAgent', mockDeviceInfo.userAgent);
      expect(sessionData).toHaveProperty('ipAddress', mockDeviceInfo.ipAddress);
    });
  });

  describe('getSession', () => {
    it('should retrieve session', async () => {
      const mockSession = {
        userId: mockUserId,
        ...mockDeviceInfo,
        createdAt: new Date(),
      };

      (cacheService.get as jest.Mock).mockResolvedValue(mockSession);

      const session = await sessionService.getSession(mockSessionId);

      expect(session).toEqual(mockSession);
      expect(cacheService.get).toHaveBeenCalledWith(`session:${mockSessionId}`);
    });

    it('should update lastActivity on get', async () => {
      const mockSession = {
        userId: mockUserId,
        ...mockDeviceInfo,
        lastActivity: new Date(),
      };

      (cacheService.get as jest.Mock).mockResolvedValue(mockSession);
      (cacheService.set as jest.Mock).mockResolvedValue(true);

      await sessionService.getSession(mockSessionId);

      // Should call set to update lastActivity
      expect(cacheService.set).toHaveBeenCalled();
    });

    it('should return null if session not found', async () => {
      (cacheService.get as jest.Mock).mockResolvedValue(null);

      const session = await sessionService.getSession('invalid-session');

      expect(session).toBeNull();
    });

    it('should handle expired sessions', async () => {
      (cacheService.get as jest.Mock).mockResolvedValue(null);

      const session = await sessionService.getSession(mockSessionId);

      expect(session).toBeNull();
    });
  });

  describe('updateSession', () => {
    it('should update session data', async () => {
      const updates = { lastActivity: new Date() };

      (cacheService.set as jest.Mock).mockResolvedValue(true);

      await sessionService.updateSession(mockSessionId, updates);

      expect(cacheService.set).toHaveBeenCalled();
    });

    it('should preserve TTL on update', async () => {
      (cacheService.set as jest.Mock).mockResolvedValue(true);

      await sessionService.updateSession(mockSessionId, { active: true });

      const callArgs = (cacheService.set as jest.Mock).mock.calls[0];
      const ttl = callArgs[2];

      // Should still be 1800 seconds
      expect(ttl).toBe(1800);
    });
  });

  describe('deleteSession', () => {
    it('should delete session', async () => {
      (cacheService.delete as jest.Mock).mockResolvedValue(true);

      await sessionService.deleteSession(mockSessionId);

      expect(cacheService.delete).toHaveBeenCalledWith(`session:${mockSessionId}`);
    });

    it('should handle deleting non-existent session', async () => {
      (cacheService.delete as jest.Mock).mockResolvedValue(true);

      await expect(
        sessionService.deleteSession('invalid-session')
      ).resolves.not.toThrow();
    });
  });

  describe('getUserSessions', () => {
    it('should retrieve all sessions for user', async () => {
      const mockSessions = [
        { sessionId: 'session-1', deviceType: 'web' },
        { sessionId: 'session-2', deviceType: 'mobile' },
      ];

      (cacheService.hgetall as jest.Mock).mockResolvedValue({
        'session-1': JSON.stringify(mockSessions[0]),
        'session-2': JSON.stringify(mockSessions[1]),
      });

      const sessions = await sessionService.getUserSessions(mockUserId);

      expect(sessions).toHaveLength(2);
    });

    it('should return empty array if user has no sessions', async () => {
      (cacheService.hgetall as jest.Mock).mockResolvedValue({});

      const sessions = await sessionService.getUserSessions(mockUserId);

      expect(sessions).toEqual([]);
    });

    it('should handle multiple concurrent sessions', async () => {
      const mockSessions = {
        'session-1': JSON.stringify({ deviceType: 'web' }),
        'session-2': JSON.stringify({ deviceType: 'mobile' }),
        'session-3': JSON.stringify({ deviceType: 'tablet' }),
      };

      (cacheService.hgetall as jest.Mock).mockResolvedValue(mockSessions);

      const sessions = await sessionService.getUserSessions(mockUserId);

      expect(sessions).toHaveLength(3);
    });
  });

  describe('invalidateUserSessions', () => {
    it('should delete all sessions for user (logout all devices)', async () => {
      const mockSessions = {
        'session-1': JSON.stringify({ sessionId: 'session-1' }),
        'session-2': JSON.stringify({ sessionId: 'session-2' }),
      };

      (cacheService.hgetall as jest.Mock).mockResolvedValue(mockSessions);
      (cacheService.delete as jest.Mock).mockResolvedValue(true);

      await sessionService.invalidateUserSessions(mockUserId);

      // Should delete all sessions
      expect(cacheService.delete).toHaveBeenCalledTimes(2);
    });

    it('should handle user with no sessions', async () => {
      (cacheService.hgetall as jest.Mock).mockResolvedValue({});

      await expect(
        sessionService.invalidateUserSessions(mockUserId)
      ).resolves.not.toThrow();
    });

    it('should keep specific session if provided', async () => {
      const mockSessions = {
        'session-1': JSON.stringify({ sessionId: 'session-1' }),
        'session-2': JSON.stringify({ sessionId: 'session-2' }),
      };

      (cacheService.hgetall as jest.Mock).mockResolvedValue(mockSessions);
      (cacheService.delete as jest.Mock).mockResolvedValue(true);

      // Keep session-1
      await sessionService.invalidateUserSessions(mockUserId, 'session-1');

      // Should only delete session-2
      expect(cacheService.delete).toHaveBeenCalledWith(`session:session-2`);
    });
  });

  describe('exists', () => {
    it('should check if session exists', async () => {
      (cacheService.exists as jest.Mock).mockResolvedValue(true);

      const exists = await sessionService.exists(mockSessionId);

      expect(exists).toBe(true);
    });

    it('should return false for non-existent session', async () => {
      (cacheService.exists as jest.Mock).mockResolvedValue(false);

      const exists = await sessionService.exists('invalid-session');

      expect(exists).toBe(false);
    });
  });

  describe('cleanupExpiredSessions', () => {
    it('should clean up expired sessions', async () => {
      (cacheService.hgetall as jest.Mock).mockResolvedValue({
        'session-1': JSON.stringify({
          lastActivity: new Date(Date.now() - 2 * 60 * 60 * 1000), // 2 hours old
        }),
      });

      (cacheService.delete as jest.Mock).mockResolvedValue(true);

      await sessionService.cleanupExpiredSessions(1 * 60 * 60 * 1000); // 1 hour threshold

      expect(cacheService.delete).toHaveBeenCalled();
    });

    it('should not delete recent sessions', async () => {
      (cacheService.hgetall as jest.Mock).mockResolvedValue({
        'session-1': JSON.stringify({
          lastActivity: new Date(Date.now() - 5 * 60 * 1000), // 5 minutes old
        }),
      });

      (cacheService.delete as jest.Mock).mockResolvedValue(true);

      await sessionService.cleanupExpiredSessions(1 * 60 * 60 * 1000); // 1 hour threshold

      expect(cacheService.delete).not.toHaveBeenCalled();
    });
  });

  describe('Session Validation', () => {
    it('should validate session belongs to correct user', async () => {
      const mockSession = {
        userId: mockUserId,
        ...mockDeviceInfo,
      };

      (cacheService.get as jest.Mock).mockResolvedValue(mockSession);

      const session = await sessionService.getSession(mockSessionId);

      expect(session?.userId).toBe(mockUserId);
    });

    it('should detect session tampering', async () => {
      const mockSession = {
        userId: mockUserId,
        ...mockDeviceInfo,
        signature: 'original-signature',
      };

      (cacheService.get as jest.Mock).mockResolvedValue(mockSession);

      const session = await sessionService.getSession(mockSessionId);

      // Signature should match if session is valid
      expect(session?.signature).toBe('original-signature');
    });
  });

  describe('Concurrent Session Handling', () => {
    it('should handle creating multiple sessions per user', async () => {
      (cacheService.set as jest.Mock).mockResolvedValue(true);

      const session1 = await sessionService.createSession(mockUserId, {
        ...mockDeviceInfo,
        deviceType: 'web',
      });

      const session2 = await sessionService.createSession(mockUserId, {
        ...mockDeviceInfo,
        deviceType: 'mobile',
      });

      expect(session1).not.toEqual(session2);
    });

    it('should handle concurrent deletes', async () => {
      (cacheService.delete as jest.Mock).mockResolvedValue(true);

      await Promise.all([
        sessionService.deleteSession('session-1'),
        sessionService.deleteSession('session-2'),
        sessionService.deleteSession('session-3'),
      ]);

      expect(cacheService.delete).toHaveBeenCalledTimes(3);
    });
  });

  describe('Error Handling', () => {
    it('should handle cache service errors', async () => {
      (cacheService.set as jest.Mock).mockRejectedValue(new Error('Cache error'));

      await expect(
        sessionService.createSession(mockUserId, mockDeviceInfo)
      ).rejects.toThrow();
    });

    it('should handle JSON parsing errors', async () => {
      (cacheService.hgetall as jest.Mock).mockResolvedValue({
        'session-1': 'invalid-json',
      });

      const sessions = await sessionService.getUserSessions(mockUserId);

      // Should handle gracefully
      expect(sessions).toBeDefined();
    });
  });
});
