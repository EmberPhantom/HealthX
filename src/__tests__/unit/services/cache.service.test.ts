import cacheService from '../../../services/cache.service';

describe('CacheService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    cacheService.clear();
  });

  describe('get and set', () => {
    it('should set and retrieve value', async () => {
      await cacheService.set('key1', 'value1', 3600);
      const value = await cacheService.get('key1');

      expect(value).toBe('value1');
    });

    it('should return null for missing key', async () => {
      const value = await cacheService.get('nonexistent');

      expect(value).toBeNull();
    });

    it('should support different data types', async () => {
      const obj = { name: 'John', age: 30 };
      await cacheService.set('obj', obj, 3600);

      const retrieved = await cacheService.get('obj');
      expect(retrieved).toEqual(obj);
    });

    it('should handle JSON serialization', async () => {
      const data = { user: 'john', roles: ['admin', 'user'] };
      await cacheService.set('data', data, 3600);

      const cached = await cacheService.get('data');
      expect(cached).toEqual(data);
    });
  });

  describe('delete', () => {
    it('should delete existing key', async () => {
      await cacheService.set('key1', 'value1', 3600);
      await cacheService.delete('key1');

      const value = await cacheService.get('key1');
      expect(value).toBeNull();
    });

    it('should handle deletion of non-existent key', async () => {
      await expect(cacheService.delete('nonexistent')).resolves.not.toThrow();
    });
  });

  describe('deleteMany', () => {
    it('should delete multiple keys', async () => {
      await cacheService.set('key1', 'value1', 3600);
      await cacheService.set('key2', 'value2', 3600);
      await cacheService.set('key3', 'value3', 3600);

      await cacheService.deleteMany(['key1', 'key2']);

      expect(await cacheService.get('key1')).toBeNull();
      expect(await cacheService.get('key2')).toBeNull();
      expect(await cacheService.get('key3')).toBe('value3');
    });
  });

  describe('clear', () => {
    it('should clear all cache', async () => {
      await cacheService.set('key1', 'value1', 3600);
      await cacheService.set('key2', 'value2', 3600);

      cacheService.clear();

      expect(await cacheService.get('key1')).toBeNull();
      expect(await cacheService.get('key2')).toBeNull();
    });
  });

  describe('exists', () => {
    it('should return true for existing key', async () => {
      await cacheService.set('key1', 'value1', 3600);

      const exists = await cacheService.exists('key1');
      expect(exists).toBe(true);
    });

    it('should return false for non-existent key', async () => {
      const exists = await cacheService.exists('nonexistent');
      expect(exists).toBe(false);
    });
  });

  describe('getOrCompute', () => {
    it('should return cached value if exists', async () => {
      await cacheService.set('computed', 'cached-value', 3600);
      const computeFn = jest.fn();

      const value = await cacheService.getOrCompute('computed', computeFn, 3600);

      expect(value).toBe('cached-value');
      expect(computeFn).not.toHaveBeenCalled();
    });

    it('should compute and cache value if not exists', async () => {
      const computeFn = jest.fn().mockResolvedValue('computed-value');

      const value = await cacheService.getOrCompute('new-key', computeFn, 3600);

      expect(value).toBe('computed-value');
      expect(computeFn).toHaveBeenCalled();

      const cached = await cacheService.get('new-key');
      expect(cached).toBe('computed-value');
    });

    it('should handle compute function errors', async () => {
      const computeFn = jest.fn().mockRejectedValue(new Error('Compute error'));

      await expect(
        cacheService.getOrCompute('error-key', computeFn, 3600)
      ).rejects.toThrow('Compute error');
    });
  });

  describe('increment', () => {
    it('should increment numeric value', async () => {
      await cacheService.set('counter', 5, 3600);

      await cacheService.increment('counter', 1);

      const value = await cacheService.get('counter');
      expect(value).toBe(6);
    });

    it('should handle non-existent counter (initialize to 0)', async () => {
      await cacheService.increment('new-counter', 1);

      const value = await cacheService.get('new-counter');
      expect(value).toBe(1);
    });

    it('should decrement with negative increment', async () => {
      await cacheService.set('counter', 10, 3600);

      await cacheService.increment('counter', -3);

      const value = await cacheService.get('counter');
      expect(value).toBe(7);
    });
  });

  describe('hash operations', () => {
    describe('hset', () => {
      it('should set hash field', async () => {
        await cacheService.hset('user:1', 'name', 'John');
        const value = await cacheService.hget('user:1', 'name');

        expect(value).toBe('John');
      });

      it('should update existing hash field', async () => {
        await cacheService.hset('user:1', 'name', 'John');
        await cacheService.hset('user:1', 'name', 'Jane');

        const value = await cacheService.hget('user:1', 'name');
        expect(value).toBe('Jane');
      });

      it('should handle multiple fields', async () => {
        await cacheService.hset('user:1', 'name', 'John');
        await cacheService.hset('user:1', 'email', 'john@example.com');

        const name = await cacheService.hget('user:1', 'name');
        const email = await cacheService.hget('user:1', 'email');

        expect(name).toBe('John');
        expect(email).toBe('john@example.com');
      });
    });

    describe('hget', () => {
      it('should return null for non-existent field', async () => {
        const value = await cacheService.hget('user:1', 'nonexistent');

        expect(value).toBeNull();
      });
    });

    describe('hgetall', () => {
      it('should return all hash fields', async () => {
        await cacheService.hset('user:1', 'name', 'John');
        await cacheService.hset('user:1', 'email', 'john@example.com');
        await cacheService.hset('user:1', 'age', '30');

        const all = await cacheService.hgetall('user:1');

        expect(all).toEqual({
          name: 'John',
          email: 'john@example.com',
          age: '30',
        });
      });

      it('should return empty object for non-existent hash', async () => {
        const all = await cacheService.hgetall('nonexistent-hash');

        expect(all).toEqual({});
      });
    });
  });

  describe('TTL handling', () => {
    it('should not set TTL for zero seconds', async () => {
      await cacheService.set('permanent', 'value', 0);
      const value = await cacheService.get('permanent');

      expect(value).toBe('value');
    });

    it('should handle different TTL values', async () => {
      const shortTTL = 60; // 1 minute
      const longTTL = 86400; // 1 day

      await cacheService.set('short', 'value1', shortTTL);
      await cacheService.set('long', 'value2', longTTL);

      expect(await cacheService.get('short')).toBe('value1');
      expect(await cacheService.get('long')).toBe('value2');
    });
  });

  describe('Error handling', () => {
    it('should handle null values', async () => {
      await cacheService.set('nullable', null, 3600);
      const value = await cacheService.get('nullable');

      expect(value).toBeNull();
    });

    it('should handle undefined values', async () => {
      await cacheService.set('undefinable', undefined, 3600);
      const value = await cacheService.get('undefinable');

      // Undefined might be serialized as null
      expect(value === null || value === undefined).toBe(true);
    });

    it('should handle circular references gracefully', async () => {
      const obj: any = { name: 'test' };
      obj.self = obj;

      await expect(
        cacheService.set('circular', obj, 3600)
      ).rejects.toThrow();
    });
  });
});
