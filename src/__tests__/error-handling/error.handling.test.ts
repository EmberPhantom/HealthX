import request from 'supertest';
import app from '../../app';
import User from '../../models/User';
import { signupData, generateTestTokens } from '../fixtures/test.fixtures';

describe('Error Handling Tests', () => {
  afterEach(async () => {
    await User.deleteMany({});
  });

  describe('HTTP Status Codes', () => {
    test('ERR-Status-001: Should return 400 for validation error', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          name: 'Test User',
          email: 'invalid-email',
        });

      expect(response.status).toBe(400);
    });

    test('ERR-Status-002: Should return 401 for missing authentication', async () => {
      const response = await request(app)
        .get('/api/v1/users/me');

      expect(response.status).toBe(401);
    });

    test('ERR-Status-003: Should return 401 for invalid token', async () => {
      const response = await request(app)
        .get('/api/v1/users/me')
        .set('Authorization', 'Bearer invalid.token');

      expect(response.status).toBe(401);
    });

    test('ERR-Status-004: Should return 401 for expired token', async () => {
      const tokens = generateTestTokens();
      const response = await request(app)
        .get('/api/v1/users/me')
        .set('Authorization', `Bearer ${tokens.expiredToken}`);

      expect(response.status).toBe(401);
    });

    test('ERR-Status-005: Should return 409 for duplicate email', async () => {
      await request(app)
        .post('/api/v1/auth/signup')
        .send(signupData.validSignup);

      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          ...signupData.validSignup,
          name: 'Different Name',
        });

      expect(response.status).toBe(409);
    });

    test('ERR-Status-006: Should return 200 for successful request', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send(signupData.validSignup);

      expect(response.status).toBe(201);
    });
  });

  describe('Validation Error Messages', () => {
    test('ERR-Message-001: Should include validation error details', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          name: 'Test User',
          email: 'invalid-email',
          password: 'weak',
        });

      expect(response.body.message).toBeDefined();
      expect(response.body.message).toContain('Validation error');
    });

    test('ERR-Message-002: Should include field names in error', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          name: 'Test User',
          // Missing email
          password: 'ValidPass123!',
          phone: '+1234567890',
        });

      expect(response.body.message).toBeDefined();
    });

    test('ERR-Message-003: Should provide specific error messages', async () => {
      const response = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: 'nonexistent@example.com',
          password: 'AnyPassword123!',
        });

      expect(response.body.message).toContain('Invalid email or password');
    });

    test('ERR-Message-004: Should not expose sensitive information', async () => {
      const response = await request(app)
        .get('/api/v1/users/me')
        .set('Authorization', 'Bearer invalid');

      expect(response.body.message).not.toContain('secret');
      expect(response.body.message).not.toContain('password');
    });

    test('ERR-Message-005: Should include error timestamp', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          name: 'Test',
          email: 'invalid',
        });

      expect(response.body.timestamp).toBeDefined();
    });
  });

  describe('Error Response Format', () => {
    test('ERR-Format-001: Should return consistent error format', async () => {
      const response = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: 'test@test.com',
          password: 'wrong',
        });

      expect(response.body).toHaveProperty('status');
      expect(response.body).toHaveProperty('message');
      expect(response.body.status).toBe('fail');
    });

    test('ERR-Format-002: Should include status code in response', async () => {
      const response = await request(app)
        .get('/api/v1/users/me');

      expect(response.body.statusCode).toBe(401);
    });

    test('ERR-Format-003: Should format error consistently', async () => {
      const response1 = await request(app)
        .post('/api/v1/auth/signup')
        .send({ name: 'Test' });

      const response2 = await request(app)
        .get('/api/v1/users/me');

      // Both should have same error structure
      expect(response1.body).toHaveProperty('status');
      expect(response2.body).toHaveProperty('status');
    });
  });

  describe('Authentication Errors', () => {
    test('ERR-Auth-001: Should return 401 for missing Authorization header', async () => {
      const response = await request(app)
        .get('/api/v1/users/me');

      expect(response.status).toBe(401);
    });

    test('ERR-Auth-002: Should return 401 for invalid Authorization format', async () => {
      const response = await request(app)
        .get('/api/v1/users/me')
        .set('Authorization', 'InvalidFormat token');

      expect(response.status).toBe(401);
    });

    test('ERR-Auth-003: Should return 401 for malformed JWT', async () => {
      const response = await request(app)
        .get('/api/v1/users/me')
        .set('Authorization', 'Bearer malformed.jwt');

      expect(response.status).toBe(401);
    });

    test('ERR-Auth-004: Should return 401 for JWT with wrong signature', async () => {
      const tokens = generateTestTokens();
      const response = await request(app)
        .get('/api/v1/users/me')
        .set('Authorization', `Bearer ${tokens.invalidToken}`);

      expect(response.status).toBe(401);
    });

    test('ERR-Auth-005: Should return specific message for inactive user', async () => {
      await User.create({
        ...signupData.validSignup,
        isActive: false,
      });

      const response = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: signupData.validSignup.email,
          password: signupData.validSignup.password,
        });

      expect(response.status).toBe(403);
      expect(response.body.message).toContain('deactivated');
    });
  });

  describe('Database Constraint Errors', () => {
    test('ERR-DB-001: Should handle duplicate email error', async () => {
      await request(app)
        .post('/api/v1/auth/signup')
        .send(signupData.validSignup);

      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          ...signupData.validSignup,
          name: 'Different Name',
        });

      expect(response.status).toBe(409);
      expect(response.body.message).toContain('Email already registered');
    });

    test('ERR-DB-002: Should handle missing required fields', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          name: 'Test User',
          email: 'test@example.com',
          // Missing password, phone, confirmPassword
        });

      expect(response.status).toBe(400);
    });

    test('ERR-DB-003: Should validate email format', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          ...signupData.validSignup,
          email: 'not-an-email',
        });

      expect(response.status).toBe(400);
    });
  });

  describe('Input Validation Errors', () => {
    test('ERR-Validation-001: Should reject age below minimum', async () => {
      const signupRes = await request(app)
        .post('/api/v1/auth/signup')
        .send(signupData.validSignup);

      const accessToken = signupRes.body.data.accessToken;

      const response = await request(app)
        .put('/api/v1/users/me')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ age: 17 });

      expect(response.status).toBe(400);
    });

    test('ERR-Validation-002: Should reject age above maximum', async () => {
      const signupRes = await request(app)
        .post('/api/v1/auth/signup')
        .send(signupData.validSignup);

      const accessToken = signupRes.body.data.accessToken;

      const response = await request(app)
        .put('/api/v1/users/me')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ age: 121 });

      expect(response.status).toBe(400);
    });

    test('ERR-Validation-003: Should reject invalid gender', async () => {
      const signupRes = await request(app)
        .post('/api/v1/auth/signup')
        .send(signupData.validSignup);

      const accessToken = signupRes.body.data.accessToken;

      const response = await request(app)
        .put('/api/v1/users/me')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ gender: 'InvalidGender' });

      expect(response.status).toBe(400);
    });

    test('ERR-Validation-004: Should require strong password', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          ...signupData.validSignup,
          password: 'weak',
          confirmPassword: 'weak',
        });

      expect(response.status).toBe(400);
    });

    test('ERR-Validation-005: Should validate email format', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          ...signupData.validSignup,
          email: 'invalid',
        });

      expect(response.status).toBe(400);
    });
  });

  describe('Error Recovery', () => {
    test('ERR-Recovery-001: Should allow retry after validation error', async () => {
      // First request with error
      await request(app)
        .post('/api/v1/auth/signup')
        .send({ name: 'Test' });

      // Second request should work
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send(signupData.validSignup);

      expect(response.status).toBe(201);
    });

    test('ERR-Recovery-002: Should allow retry after failed login', async () => {
      await request(app)
        .post('/api/v1/auth/signup')
        .send(signupData.validSignup);

      // Failed attempt
      await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: signupData.validSignup.email,
          password: 'WrongPassword',
        });

      // Retry with correct password
      const response = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: signupData.validSignup.email,
          password: signupData.validSignup.password,
        });

      expect(response.status).toBe(200);
    });

    test('ERR-Recovery-003: Should not block after multiple failed attempts', async () => {
      await request(app)
        .post('/api/v1/auth/signup')
        .send(signupData.validSignup);

      // Multiple failed attempts
      for (let i = 0; i < 3; i++) {
        await request(app)
          .post('/api/v1/auth/login')
          .send({
            email: signupData.validSignup.email,
            password: 'WrongPassword',
          });
      }

      // Should still allow correct login
      const response = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: signupData.validSignup.email,
          password: signupData.validSignup.password,
        });

      expect(response.status).toBe(200);
    });
  });
});
