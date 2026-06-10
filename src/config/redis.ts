import Redis from 'ioredis';
import logger from '../utils/logger';

/**
 * Redis configuration for Phase 2+
 * Manages connection to Redis server for caching, sessions, and rate limiting
 */

let redisClient: Redis | null = null;
let redisConnected = false;

/**
 * Initialize Redis connection
 */
export const initializeRedis = async (): Promise<void> => {
  try {
    const redisUrl = process.env.REDIS_URL || 'redis://localhost:6379';
    const redisPassword = process.env.REDIS_PASSWORD;

    const redisOptions: any = {
      retryStrategy: (times: number) => {
        const delay = Math.min(times * 50, 2000);
        return delay;
      },
      reconnectOnError: (err: Error) => {
        const targetError = 'READONLY';
        if (err.message.includes(targetError)) {
          return true; // Reconnect when the error contains "READONLY"
        }
        return false;
      },
      enableReadyCheck: false,
      enableOfflineQueue: true,
      connectTimeout: 10000,
      commandTimeout: 5000,
    };

    if (redisPassword) {
      redisOptions.password = redisPassword;
    }

    redisClient = new Redis(redisUrl, redisOptions);

    redisClient.on('connect', () => {
      logger.info('✓ Redis connected successfully');
      redisConnected = true;
    });

    redisClient.on('error', (err: Error) => {
      logger.warn('Redis connection error:', err.message);
      redisConnected = false;
    });

    redisClient.on('close', () => {
      logger.warn('Redis connection closed');
      redisConnected = false;
    });

    // Test connection
    await redisClient.ping();
    logger.info('Redis is ready');
  } catch (error) {
    logger.warn('Failed to connect to Redis, falling back to in-memory mode:', error);
    redisConnected = false;
  }
};

/**
 * Get Redis client
 */
export const getRedisClient = (): Redis | null => {
  return redisClient;
};

/**
 * Check if Redis is connected
 */
export const isRedisConnected = (): boolean => {
  return redisConnected && redisClient !== null;
};

/**
 * Close Redis connection
 */
export const closeRedis = async (): Promise<void> => {
  if (redisClient) {
    await redisClient.quit();
    redisConnected = false;
    logger.info('Redis connection closed');
  }
};

export default redisClient;
