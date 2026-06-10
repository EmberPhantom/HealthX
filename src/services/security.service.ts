import { v4 as uuidv4 } from 'uuid';
import AuditLog from '../models/AuditLog';
import LoginAttempt from '../models/LoginAttempt';
import User from '../models/User';
import { AppError } from '../utils/AppError';
import logger from '../utils/logger';

interface SecurityConfig {
  maxLoginAttempts: number;
  lockoutDurationMinutes: number;
  rateLimitWindowMinutes: number;
  rateLimitMaxRequests: number;
}

class SecurityService {
  private config: SecurityConfig = {
    maxLoginAttempts: 5,
    lockoutDurationMinutes: 15,
    rateLimitWindowMinutes: 15,
    rateLimitMaxRequests: 10,
  };

  private rateLimitInMemoryStore = new Map<string, { count: number; resetAt: number }>();

  /**
   * Generate CSRF token
   */
  generateCSRFToken(): string {
    return uuidv4();
  }

  /**
   * Track login attempt
   */
  async trackLoginAttempt(
    email: string,
    ipAddress: string,
    success: boolean,
    userAgent?: string,
    userId?: string
  ): Promise<{ isBlocked: boolean; blockedUntil?: Date }> {
    try {
      // Create login attempt record
      const attempt = await LoginAttempt.create({
        userId: userId || null,
        email,
        ipAddress,
        success,
        userAgent,
        consecutiveFailures: success ? 0 : 1,
      });

      // If login failed, check if account should be locked
      if (!success) {
        const recentFailures = await LoginAttempt.countDocuments({
          email,
          success: false,
          attemptedAt: {
            $gte: new Date(Date.now() - 30 * 60 * 1000), // Last 30 minutes
          },
        });

        if (recentFailures >= this.config.maxLoginAttempts) {
          const blockedUntil = new Date(
            Date.now() + this.config.lockoutDurationMinutes * 60 * 1000
          );

          // Update all attempts to show blocked status
          await LoginAttempt.updateMany(
            { email },
            {
              isBlocked: true,
              blockedUntil,
            }
          );

          // Log security event
          await this.logSecurityEvent(
            null,
            'ACCOUNT_LOCKED',
            'authentication',
            'POST',
            '/api/v1/auth/login',
            429,
            ipAddress,
            userAgent,
            {
              email,
              reason: 'Too many failed login attempts',
              consecutiveFailures: recentFailures,
            },
            false,
            'Account locked due to multiple failed login attempts'
          );

          return { isBlocked: true, blockedUntil };
        }
      } else if (success && userId) {
        // Reset failed attempts on successful login
        await LoginAttempt.updateMany(
          { email, userId },
          { consecutiveFailures: 0 }
        );
      }

      return { isBlocked: false };
    } catch (error) {
      logger.error('Error tracking login attempt:', error);
      throw error;
    }
  }

  /**
   * Check if account is locked
   */
  async isAccountLocked(email: string): Promise<{
    locked: boolean;
    blockedUntil?: Date;
  }> {
    try {
      const attempt = await LoginAttempt.findOne(
        { email, isBlocked: true },
        {},
        { sort: { blockedUntil: -1 } }
      );

      if (!attempt) {
        return { locked: false };
      }

      if (attempt.blockedUntil && new Date() > attempt.blockedUntil) {
        // Unlock account
        await LoginAttempt.updateMany(
          { email },
          { isBlocked: false, blockedUntil: null }
        );
        return { locked: false };
      }

      return { locked: true, blockedUntil: attempt.blockedUntil };
    } catch (error) {
      logger.error('Error checking account lock:', error);
      throw error;
    }
  }

  /**
   * Check rate limiting using Redis atomic counters
   * Falls back to in-memory check if Redis is unavailable
   */
  async checkRateLimit(
    identifier: string, // IP address or user ID
    limit: number = this.config.rateLimitMaxRequests,
    windowMinutes: number = this.config.rateLimitWindowMinutes
  ): Promise<{ allowed: boolean; remaining: number; resetAt: Date }> {
    try {
      const { isRedisConnected, getRedisClient } = await import('../config/redis');
      const windowSeconds = windowMinutes * 60;
      const key = `ratelimit:${identifier}`;
      const resetAt = new Date(Date.now() + windowSeconds * 1000);

      if (isRedisConnected()) {
        const client = getRedisClient()!;
        const current = await client.incr(key);
        // Set expiry only on first request in window
        if (current === 1) {
          await client.expire(key, windowSeconds);
        }
        const ttl = await client.ttl(key);
        const allowed = current <= limit;
        const remaining = Math.max(0, limit - current);
        return {
          allowed,
          remaining,
          resetAt: new Date(Date.now() + ttl * 1000),
        };
      }

      // Fallback: in-memory rate limit (single-process only)
      const now = Date.now();
      const windowMs = windowMinutes * 60 * 1000;
      const record = this.rateLimitInMemoryStore.get(identifier);
      if (!record || now > record.resetAt) {
        const newResetAt = new Date(now + windowMs);
        this.rateLimitInMemoryStore.set(identifier, { count: 1, resetAt: newResetAt.getTime() });
        return { allowed: true, remaining: limit - 1, resetAt: newResetAt };
      }
      record.count++;
      const remaining = Math.max(0, limit - record.count);
      const allowed = record.count <= limit;
      return { allowed, remaining, resetAt: new Date(record.resetAt) };
    } catch (error) {
      logger.error('Error checking rate limit:', error);
      if (process.env.NODE_ENV === 'test') {
        throw error;
      }
      // Fail open - allow request if check fails
      return {
        allowed: true,
        remaining: this.config.rateLimitMaxRequests,
        resetAt: new Date(),
      };
    }
  }

  /**
   * Log security event
   */
  async logSecurityEvent(
    userId: string | null,
    action: 'LOGIN' | 'LOGOUT' | 'SIGNUP' | 'PASSWORD_CHANGE' | 'PROFILE_UPDATE' | 'OAUTH_LOGIN' | 'FAILED_LOGIN' | 'ACCOUNT_LOCKED',
    resource: string,
    method: string,
    endpoint: string,
    status: number,
    ipAddress: string,
    userAgent?: string,
    details?: Record<string, any>,
    success?: boolean,
    errorMessage?: string
  ): Promise<void> {
    try {
      await AuditLog.create({
        userId: userId || null,
        action,
        resource,
        method,
        endpoint,
        status,
        ipAddress,
        userAgent,
        details,
        success: success !== false,
        errorMessage,
        timestamp: new Date(),
      });
    } catch (error) {
      logger.error('Error logging security event:', error);
      // Don't throw - logging failures shouldn't break the application
    }
  }

  /**
   * Get login history for user
   */
  async getLoginHistory(
    userId: string,
    limit: number = 10
  ): Promise<any[]> {
    try {
      return await AuditLog.find(
        { userId, action: 'LOGIN' },
        { _id: 0, userId: 0 },
        { sort: { timestamp: -1 }, limit }
      );
    } catch (error) {
      logger.error('Error getting login history:', error);
      throw error;
    }
  }

  /**
   * Get suspicious activity
   */
  async getSuspiciousActivity(ipAddress: string): Promise<{
    failedAttempts: number;
    lastAttempt?: Date;
    isBlocked: boolean;
    blockDetails?: { blockedUntil: Date; reason: string };
  }> {
    try {
      const failedAttempts = await LoginAttempt.countDocuments({
        ipAddress,
        success: false,
        attemptedAt: {
          $gte: new Date(Date.now() - 60 * 60 * 1000), // Last hour
        },
      });

      const lastAttempt = await LoginAttempt.findOne(
        { ipAddress },
        { attemptedAt: 1 },
        { sort: { attemptedAt: -1 } }
      );

      const blockedAttempt = await LoginAttempt.findOne(
        { ipAddress, isBlocked: true },
        { blockedUntil: 1, email: 1 },
        { sort: { blockedUntil: -1 } }
      );

      return {
        failedAttempts,
        lastAttempt: lastAttempt?.attemptedAt,
        isBlocked: !!blockedAttempt && (!blockedAttempt.blockedUntil || new Date() < blockedAttempt.blockedUntil),
        blockDetails: blockedAttempt ? {
          blockedUntil: blockedAttempt.blockedUntil!,
          reason: `Too many failed attempts for email: ${blockedAttempt.email}`,
        } : undefined,
      };
    } catch (error) {
      logger.error('Error getting suspicious activity:', error);
      throw error;
    }
  }

  /**
   * Clear failed login attempts for email
   */
  async clearFailedAttempts(email: string): Promise<void> {
    try {
      await LoginAttempt.deleteMany({ email, success: false });
    } catch (error) {
      logger.error('Error clearing failed attempts:', error);
      throw error;
    }
  }
}

export default new SecurityService();
