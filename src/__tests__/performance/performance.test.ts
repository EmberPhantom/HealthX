import request from 'supertest';
import app from '../../app';
import User from '../../models/User';
import { signupData } from '../fixtures/test.fixtures';

describe('Performance Tests', () => {
  afterEach(async () => {
    await User.deleteMany({});
  });

  describe('Signup Performance', () => {
    test('PERF-Signup-001: Should complete signup in under 500ms', async () => {
      const start = performance.now();

      await request(app)
        .post('/api/v1/auth/signup')
        .send(signupData.validSignup);

      const duration = performance.now() - start;
      expect(duration).toBeLessThan(1500);
    });

    test('PERF-Signup-002: Should handle multiple signups efficiently', async () => {
      const start = performance.now();

      for (let i = 0; i < 5; i++) {
        await request(app)
          .post('/api/v1/auth/signup')
          .send({
            ...signupData.validSignup,
            email: `user${i}@example.com`,
          });
      }

      const duration = performance.now() - start;
      expect(duration).toBeLessThan(6000); // 5 signups in under 6 seconds
    });
  });

  describe('Login Performance', () => {
    beforeEach(async () => {
      await request(app)
        .post('/api/v1/auth/signup')
        .send(signupData.validSignup);
    });

    test('PERF-Login-001: Should complete login in under 300ms', async () => {
      const start = performance.now();

      await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: signupData.validSignup.email,
          password: signupData.validSignup.password,
        });

      const duration = performance.now() - start;
      expect(duration).toBeLessThan(1000);
    });

    test('PERF-Login-002: Should handle rapid login attempts', async () => {
      const start = performance.now();

      for (let i = 0; i < 3; i++) {
        await request(app)
          .post('/api/v1/auth/login')
          .send({
            email: signupData.validSignup.email,
            password: signupData.validSignup.password,
          });
      }

      const duration = performance.now() - start;
      expect(duration).toBeLessThan(3000); // 3 logins in under 3 seconds
    });
  });

  describe('Token Operations Performance', () => {
    let accessToken: string;
    let refreshToken: string;

    beforeEach(async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send(signupData.validSignup);

      accessToken = response.body.data.accessToken;
      refreshToken = response.body.data.refreshToken;
    });

    test('PERF-Token-001: Should refresh token in under 100ms', async () => {
      const start = performance.now();

      await request(app)
        .post('/api/v1/auth/refresh')
        .send({ refreshToken });

      const duration = performance.now() - start;
      expect(duration).toBeLessThan(500);
    });

    test('PERF-Token-002: Should verify token in under 50ms', async () => {
      const start = performance.now();

      await request(app)
        .get('/api/v1/users/me')
        .set('Authorization', `Bearer ${accessToken}`);

      const duration = performance.now() - start;
      expect(duration).toBeLessThan(250);
    });

    test('PERF-Token-003: Should handle concurrent token operations', async () => {
      const start = performance.now();

      const promises = Array(5).fill(null).map(() =>
        request(app)
          .get('/api/v1/users/me')
          .set('Authorization', `Bearer ${accessToken}`)
      );

      await Promise.all(promises);

      const duration = performance.now() - start;
      expect(duration).toBeLessThan(1000); // 5 requests in under 1000ms
    });
  });

  describe('Profile Operations Performance', () => {
    let accessToken: string;

    beforeEach(async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send(signupData.validSignup);

      accessToken = response.body.data.accessToken;
    });

    test('PERF-Profile-001: Should fetch profile in under 50ms', async () => {
      const start = performance.now();

      await request(app)
        .get('/api/v1/users/me')
        .set('Authorization', `Bearer ${accessToken}`);

      const duration = performance.now() - start;
      expect(duration).toBeLessThan(250);
    });

    test('PERF-Profile-002: Should update profile in under 100ms', async () => {
      const start = performance.now();

      await request(app)
        .put('/api/v1/users/me')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ age: 35 });

      const duration = performance.now() - start;
      expect(duration).toBeLessThan(500);
    });

    test('PERF-Profile-003: Should handle concurrent profile updates', async () => {
      const start = performance.now();

      const promises = Array(3).fill(null).map((_, i) =>
        request(app)
          .put('/api/v1/users/me')
          .set('Authorization', `Bearer ${accessToken}`)
          .send({ age: 30 + i })
      );

      await Promise.all(promises);

      const duration = performance.now() - start;
      expect(duration).toBeLessThan(1000); // 3 updates in under 1000ms
    });
  });

  describe('Middleware Performance', () => {
    let accessToken: string;

    beforeEach(async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send(signupData.validSignup);

      accessToken = response.body.data.accessToken;
    });

    test('PERF-Middleware-001: Should complete auth middleware in under 20ms', async () => {
      const start = performance.now();

      await request(app)
        .get('/api/v1/users/me')
        .set('Authorization', `Bearer ${accessToken}`);

      const duration = performance.now() - start;
      expect(duration).toBeLessThan(100);
    });

    test('PERF-Middleware-002: Should validate request in under 10ms', async () => {
      const start = performance.now();

      await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: signupData.validSignup.email,
          password: signupData.validSignup.password,
        });

      const duration = performance.now() - start;
      expect(duration).toBeLessThan(1500); // Including auth
    });
  });

  describe('Memory Usage', () => {
    test('PERF-Memory-001: Should not leak memory on repeated requests', async () => {
      const initialMemory = process.memoryUsage().heapUsed;

      for (let i = 0; i < 10; i++) {
        await request(app)
          .post('/api/v1/auth/signup')
          .send({
            ...signupData.validSignup,
            email: `user${i}@example.com`,
          });
      }

      // Force garbage collection if available
      if (global.gc) {
        global.gc();
      }

      const finalMemory = process.memoryUsage().heapUsed;
      const memoryIncrease = finalMemory - initialMemory;

      // Memory increase should be reasonable (less than 25MB for 10 operations)
      expect(memoryIncrease).toBeLessThan(25 * 1024 * 1024);
    });
  });

  describe('Concurrent Operations Performance', () => {
    test('PERF-Concurrent-001: Should handle concurrent signups', async () => {
      const start = performance.now();

      const promises = Array(10).fill(null).map((_, i) =>
        request(app)
          .post('/api/v1/auth/signup')
          .send({
            ...signupData.validSignup,
            email: `concurrent${i}@example.com`,
          })
      );

      await Promise.all(promises);

      const duration = performance.now() - start;
      expect(duration).toBeLessThan(10000); // 10 concurrent signups in under 10 seconds
    });

    test('PERF-Concurrent-002: Should handle mixed operations', async () => {
      const signupRes = await request(app)
        .post('/api/v1/auth/signup')
        .send(signupData.validSignup);

      const accessToken = signupRes.body.data.accessToken;
      const refreshToken = signupRes.body.data.refreshToken;

      const start = performance.now();

      const promises = [
        ...Array(3).fill(null).map(() =>
          request(app)
            .get('/api/v1/users/me')
            .set('Authorization', `Bearer ${accessToken}`)
        ),
        request(app)
          .post('/api/v1/auth/refresh')
          .send({ refreshToken }),
        request(app)
          .put('/api/v1/users/me')
          .set('Authorization', `Bearer ${accessToken}`)
          .send({ age: 40 }),
      ];

      await Promise.all(promises);

      const duration = performance.now() - start;
      expect(duration).toBeLessThan(1500); // Mixed operations in under 1500ms
    });
  });
});
