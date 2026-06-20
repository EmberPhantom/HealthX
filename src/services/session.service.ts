import { getRedisClient, isRedisConnected } from '../config/redis';
import cacheService from './cache.service';
import logger from '../utils/logger';
import { v4 as uuidv4 } from 'uuid';

/**
 * Session Service
 * Manages user sessions using Redis with fallback to in-memory storage
 */

interface Session {
  sessionId?: string;
  userId: string;
  email: string;
  role: string;
  ipAddress: string;
  userAgent: string;
  createdAt: Date;
  lastActivity: Date;
  expiresAt: Date;
  deviceType?: string;
}

class SessionService {
  private sessionKeyPrefix = 'session:';
  private sessionTTL = 30 * 60; // 30 minutes

  /**
   * Create a new session
   */
  async createSession(
    userId: string,
    deviceInfo: { userAgent?: string; ipAddress?: string; deviceType?: string } = {}
  ): Promise<Session> {
    try {
      const sessionId = uuidv4();
      const session: Session = {
        sessionId,
        userId,
        email: '',
        role: 'user',
        ipAddress: deviceInfo.ipAddress || '',
        userAgent: deviceInfo.userAgent || '',
        deviceType: deviceInfo.deviceType || 'web',
        createdAt: new Date(),
        lastActivity: new Date(),
        expiresAt: new Date(Date.now() + this.sessionTTL * 1000),
      };

      const key = `${this.sessionKeyPrefix}${sessionId}`;
      await cacheService.set(key, session, this.sessionTTL);
      
      // Store in sessions hash for cleanup
      await cacheService.hset('sessions', sessionId, session);

      logger.info(`Session created: ${sessionId}`);
      return session;
    } catch (error) {
      logger.error('Session creation error:', error);
      throw error;
    }
  }

  /**
   * Get session by ID
   */
  async getSession(sessionId: string): Promise<Session | null> {
    try {
      const key = `${this.sessionKeyPrefix}${sessionId}`;
      const session = await cacheService.get<Session>(key);

      if (session) {
        // Update last activity
        session.lastActivity = new Date();
        await cacheService.set(key, session, this.sessionTTL);
      }

      return session;
    } catch (error) {
      logger.error('Session retrieval error:', error);
      return null;
    }
  }

  /**
   * Update session
   */
  async updateSession(
    sessionId: string,
    updates: Partial<Session>
  ): Promise<Session | null> {
    try {
      const key = `${this.sessionKeyPrefix}${sessionId}`;
      const session = await cacheService.get<Session>(key) || {} as Session;

      const updated = {
        ...session,
        ...updates,
        lastActivity: new Date(),
      };

      await cacheService.set(key, updated, this.sessionTTL);

      return updated;
    } catch (error) {
      logger.error('Session update error:', error);
      return null;
    }
  }

  /**
   * Delete session
   */
  async deleteSession(sessionId: string): Promise<void> {
    try {
      const key = `${this.sessionKeyPrefix}${sessionId}`;
      await cacheService.delete(key);
      await cacheService.hdel('sessions', sessionId);
      logger.info(`Session deleted: ${sessionId}`);
    } catch (error) {
      logger.error('Session deletion error:', error);
    }
  }

  /**
   * Get all sessions for a user
   */
  async getUserSessions(userId: string): Promise<Session[]> {
    try {
      const all = await cacheService.hgetall('sessions');

      const sessions: Session[] = [];
      for (const [sessionId, sessionStr] of Object.entries(all)) {
        try {
          const session = typeof sessionStr === 'string' ? JSON.parse(sessionStr) : sessionStr;
          if (session) {
            sessions.push(session);
          }
        } catch (e) {
          // ignore
        }
      }
      return sessions;
    } catch (error) {
      logger.error('Get user sessions error:', error);
      return [];
    }
  }

  /**
   * Invalidate all sessions for a user (logout all devices)
   */
  async invalidateUserSessions(userId: string, keepSessionId?: string): Promise<number> {
    try {
      const sessions = await this.getUserSessions(userId);
      let count = 0;

      for (const session of sessions) {
        const sessionId = session.sessionId;
        if (sessionId && sessionId !== keepSessionId) {
          await cacheService.delete(`${this.sessionKeyPrefix}${sessionId}`);
          count++;
        }
      }

      logger.info(`Invalidated ${count} sessions for user: ${userId}`);
      return count;
    } catch (error) {
      logger.error('Session invalidation error:', error);
      return 0;
    }
  }

  /**
   * Check if session exists
   */
  async exists(sessionId: string): Promise<boolean> {
    try {
      const key = `${this.sessionKeyPrefix}${sessionId}`;
      return await cacheService.exists(key);
    } catch (error) {
      logger.error('Session exists check error:', error);
      return false;
    }
  }

  /**
   * Cleanup expired sessions
   */
  async cleanupExpiredSessions(thresholdMs: number = 30 * 60 * 1000): Promise<number> {
    try {
      const all = await cacheService.hgetall('sessions');
      let count = 0;

      for (const [sessionId, sessionStr] of Object.entries(all)) {
        try {
          const session = typeof sessionStr === 'string' ? JSON.parse(sessionStr) : sessionStr;
          if (session && session.lastActivity) {
            const lastActivityTime = new Date(session.lastActivity).getTime();
            if (Date.now() - lastActivityTime > thresholdMs) {
              await cacheService.delete(`${this.sessionKeyPrefix}${sessionId}`);
              await cacheService.hdel('sessions', sessionId);
              count++;
            }
          }
        } catch (e) {
          // ignore
        }
      }

      logger.info(`Cleaned up ${count} expired sessions`);
      return count;
    } catch (error) {
      logger.error('Session cleanup error:', error);
      return 0;
    }
  }
}

export default new SessionService();
