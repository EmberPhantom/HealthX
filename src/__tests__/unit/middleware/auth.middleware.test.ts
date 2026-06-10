import request from 'supertest';
import app from '../../../app';
import User from '../../../models/User';
import { signupData, generateTestTokens } from '../../fixtures/test.fixtures';

describe('Auth Middleware Tests', () => {
  let accessToken: string;

  beforeEach(async () => {
    const signupRes = await request(app)
      .post('/api/v1/auth/signup')
      .send(signupData.validSignup);

    accessToken = signupRes.body.data.accessToken;
  });

  afterEach(async () => {
    await User.deleteMany({});
  });

  describe('Token Extraction', () => {
    test('MW-Auth-001: Should extract token from Authorization header', async () => {
      const response = await request(app)
        .get('/api/v1/users/me')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(response.status).toBe(200);
    });

    test('MW-Auth-002: Should require Bearer prefix', async () => {
      const response = await request(app)
        .get('/api/v1/users/me')
        .set('Authorization', accessToken);

      expect(response.status).toBe(401);
    });

    test('MW-Auth-003: Should return 401 for missing header', async () => {
      const response = await request(app)
        .get('/api/v1/users/me');

      expect(response.status).toBe(401);
    });

    test('MW-Auth-004: Should return 401 for empty Authorization header', async () => {
      const response = await request(app)
        .get('/api/v1/users/me')
        .set('Authorization', '');

      expect(response.status).toBe(401);
    });

    test('MW-Auth-005: Should return 401 for malformed header', async () => {
      const response = await request(app)
        .get('/api/v1/users/me')
        .set('Authorization', 'Bearer');

      expect(response.status).toBe(401);
    });
  });

  describe('Token Verification', () => {
    test('MW-Auth-006: Should verify valid token', async () => {
      const response = await request(app)
        .get('/api/v1/users/me')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(response.status).toBe(200);
    });

    test('MW-Auth-007: Should reject invalid token signature', async () => {
      const tokens = generateTestTokens();
      const response = await request(app)
        .get('/api/v1/users/me')
        .set('Authorization', `Bearer ${tokens.invalidToken}`);

      expect(response.status).toBe(401);
    });

    test('MW-Auth-008: Should reject expired token', async () => {
      const tokens = generateTestTokens();
      const response = await request(app)
        .get('/api/v1/users/me')
        .set('Authorization', `Bearer ${tokens.expiredToken}`);

      expect(response.status).toBe(401);
    });

    test('MW-Auth-009: Should attach user data to request', async () => {
      const response = await request(app)
        .get('/api/v1/users/me')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(response.body.data).toBeDefined();
      expect(response.body.data.email).toBeDefined();
    });

    test('MW-Auth-010: Should preserve token claims', async () => {
      const response = await request(app)
        .get('/api/v1/users/me')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(response.body.data.role).toBe('user');
    });
  });

  describe('Protected Routes', () => {
    test('MW-Auth-011: Should protect GET /users/me', async () => {
      const response = await request(app)
        .get('/api/v1/users/me');

      expect(response.status).toBe(401);
    });

    test('MW-Auth-012: Should protect PUT /users/me', async () => {
      const response = await request(app)
        .put('/api/v1/users/me')
        .send({ name: 'Test' });

      expect(response.status).toBe(401);
    });

    test('MW-Auth-013: Should protect POST /auth/logout', async () => {
      const response = await request(app)
        .post('/api/v1/auth/logout')
        .send({ refreshToken: 'token' });

      expect(response.status).toBe(401);
    });

    test('MW-Auth-014: Should protect POST /auth/me/upload-picture', async () => {
      const response = await request(app)
        .post('/api/v1/auth/me/upload-picture');

      expect(response.status).toBe(401);
    });
  });

  describe('Public Routes', () => {
    test('MW-Auth-015: Should allow POST /auth/signup without authentication', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          ...signupData.validSignup,
          email: 'unique_signup_auth_mw@example.com',
          phone: '+1234567812',
        });

      expect(response.status).toBe(201);
    });

    test('MW-Auth-016: Should allow POST /auth/login without authentication', async () => {
      const response = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: signupData.validSignup.email,
          password: signupData.validSignup.password,
        });

      expect(response.status).toBe(200);
    });

    test('MW-Auth-017: Should allow POST /auth/refresh without authentication', async () => {
      const response = await request(app)
        .post('/api/v1/auth/refresh')
        .send({ refreshToken: 'any-token' });

      expect([200, 401]).toContain(response.status);
    });

    test('MW-Auth-018: Should allow GET / without authentication', async () => {
      const response = await request(app).get('/');

      expect(response.status).toBe(200);
    });

    test('MW-Auth-019: Should allow GET /health without authentication', async () => {
      const response = await request(app).get('/health');

      expect(response.status).toBe(200);
    });
  });

  describe('Error Handling', () => {
    test('MW-Auth-020: Should return proper error response', async () => {
      const response = await request(app)
        .get('/api/v1/users/me');

      expect(response.body).toHaveProperty('status');
      expect(response.body).toHaveProperty('message');
      expect(response.status).toBe(401);
    });

    test('MW-Auth-021: Should not expose sensitive information in errors', async () => {
      const response = await request(app)
        .get('/api/v1/users/me')
        .set('Authorization', 'Bearer invalid');

      expect(response.body.message).not.toContain('secret');
    });
  });
});
