import { getRedisClient, isRedisConnected } from '../config/redis';
import logger from '../utils/logger';

/**
 * Cache Service
 * Handles caching operations using Redis with fallback to in-memory cache
 */

// In-memory cache fallback
const inMemoryCache = new Map<string, { value: any; expiresAt: number }>();

class CacheService {
  /**
   * Get value from cache
   */
  async get<T>(key: string): Promise<T | null> {
    try {
      if (isRedisConnected()) {
        const redisClient = getRedisClient();
        const value = await redisClient!.get(key);
        if (value) {
          return JSON.parse(value) as T;
        }
      } else {
        // Fallback to in-memory cache
        const cached = inMemoryCache.get(key);
        if (cached && (cached.expiresAt === Infinity || cached.expiresAt > Date.now())) {
          return cached.value as T;
        }
        inMemoryCache.delete(key);
      }
    } catch (error) {
      logger.error('Cache get error:', error);
    }
    return null;
  }

  /**
   * Set value in cache with TTL (Time To Live) in seconds
   */
  async set<T>(key: string, value: T, ttlSeconds: number = 3600): Promise<void> {
    try {
      if (isRedisConnected()) {
        await getRedisClient()!.setex(key, ttlSeconds, JSON.stringify(value));
      } else {
        // Validate by trying to serialize to JSON to catch circular structures
        JSON.stringify(value);
        // Fallback to in-memory cache
        inMemoryCache.set(key, {
          value,
          expiresAt: ttlSeconds > 0 ? Date.now() + ttlSeconds * 1000 : Infinity,
        });
      }
    } catch (error) {
      logger.error('Cache set error:', error);
      throw error;
    }
  }

  /**
   * Delete key from cache
   */
  async delete(key: string): Promise<void> {
    try {
      if (isRedisConnected()) {
        const redisClient = getRedisClient();
        await redisClient!.del(key);
      } else {
        // Fallback to in-memory cache
        inMemoryCache.delete(key);
      }
    } catch (error) {
      logger.error('Cache delete error:', error);
    }
  }

  /**
   * Delete multiple keys
   */
  async deleteMany(keys: string[]): Promise<void> {
    try {
      if (isRedisConnected()) {
        const redisClient = getRedisClient();
        if (keys.length > 0) {
          await redisClient!.del(...keys);
        }
      } else {
        // Fallback to in-memory cache
        keys.forEach((key) => inMemoryCache.delete(key));
      }
    } catch (error) {
      logger.error('Cache deleteMany error:', error);
    }
  }

  /**
   * Clear all cache
   */
  async clear(): Promise<void> {
    try {
      if (isRedisConnected()) {
        const redisClient = getRedisClient();
        await redisClient!.flushall();
      } else {
        // Fallback to in-memory cache
        inMemoryCache.clear();
      }
    } catch (error) {
      logger.error('Cache clear error:', error);
    }
  }

  /**
   * Check if key exists
   */
  async exists(key: string): Promise<boolean> {
    try {
      if (isRedisConnected()) {
        const redisClient = getRedisClient();
        return (await redisClient!.exists(key)) === 1;
      } else {
        // Fallback to in-memory cache
        const cached = inMemoryCache.get(key);
        return cached !== undefined && (cached.expiresAt === Infinity || cached.expiresAt > Date.now());
      }
    } catch (error) {
      logger.error('Cache exists error:', error);
      return false;
    }
  }

  /**
   * Get value or compute if not cached
   */
  async getOrCompute<T>(
    key: string,
    computeFn: () => Promise<T>,
    ttlSeconds: number = 3600
  ): Promise<T> {
    try {
      // Try to get from cache
      const cached = await this.get<T>(key);
      if (cached !== null) {
        return cached;
      }

      // Compute value
      const value = await computeFn();

      // Store in cache
      await this.set(key, value, ttlSeconds);

      return value;
    } catch (error) {
      logger.error('Cache getOrCompute error:', error);
      throw error;
    }
  }

  /**
   * Increment counter
   */
  async increment(key: string, by: number = 1): Promise<number> {
    try {
      if (isRedisConnected()) {
        const redisClient = getRedisClient();
        return await redisClient!.incrby(key, by);
      } else {
        // Fallback to in-memory cache
        const cached = inMemoryCache.get(key);
        let value = 0;

        if (cached && (cached.expiresAt === Infinity || cached.expiresAt > Date.now())) {
          value = cached.value as number;
        }

        value += by;
        inMemoryCache.set(key, { value, expiresAt: Infinity });
        return value;
      }
    } catch (error) {
      logger.error('Cache increment error:', error);
      throw error;
    }
  }

  /**
   * Set hash field
   */
  async hset(key: string, field: string, value: any): Promise<number> {
    try {
      if (isRedisConnected()) {
        const redisClient = getRedisClient();
        return await redisClient!.hset(key, field, JSON.stringify(value));
      } else {
        // Fallback: store as a regular key
        await this.set(`${key}:${field}`, value);
        return 1;
      }
    } catch (error) {
      logger.error('Cache hset error:', error);
      throw error;
    }
  }

  /**
   * Get hash field
   */
  async hget(key: string, field: string): Promise<any | null> {
    try {
      if (isRedisConnected()) {
        const redisClient = getRedisClient();
        const value = await redisClient!.hget(key, field);
        return value ? JSON.parse(value) : null;
      } else {
        // Fallback: treat as a regular key
        return await this.get(`${key}:${field}`);
      }
    } catch (error) {
      logger.error('Cache hget error:', error);
      return null;
    }
  }

  /**
   * Get all hash fields
   */
  async hgetall(key: string): Promise<Record<string, any>> {
    try {
      if (isRedisConnected()) {
        const redisClient = getRedisClient();
        const obj = await redisClient!.hgetall(key);
        
        const parsed: Record<string, any> = {};
        for (const [k, v] of Object.entries(obj)) {
          try {
            parsed[k] = JSON.parse(v as string);
          } catch {
            parsed[k] = v;
          }
        }
        return parsed;
      } else {
        // Fallback: scan inMemoryCache for keys starting with `${key}:`
        const parsed: Record<string, any> = {};
        const prefix = `${key}:`;
        for (const [k, cached] of inMemoryCache.entries()) {
          if (k.startsWith(prefix) && (cached.expiresAt === Infinity || cached.expiresAt > Date.now())) {
            const field = k.substring(prefix.length);
            parsed[field] = cached.value;
          }
        }
        return parsed;
      }
    } catch (error) {
      logger.error('Cache hgetall error:', error);
      return {};
    }
  }
}

export default new CacheService();
