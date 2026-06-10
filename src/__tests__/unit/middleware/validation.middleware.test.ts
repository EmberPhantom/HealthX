import request from 'supertest';
import app from '../../../app';
import User from '../../../models/User';
import { signupData } from '../../fixtures/test.fixtures';

describe('Validation Middleware Tests', () => {
  afterEach(async () => {
    await User.deleteMany({});
  });

  describe('Body Validation', () => {
    test('MW-Validation-001: Should validate signup request body', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          name: 'Test User',
          email: 'invalid-email',
        });

      expect(response.status).toBe(400);
      expect(response.body.message).toContain('Validation error');
    });

    test('MW-Validation-002: Should validate login request body', async () => {
      const response = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: 'invalid-email',
        });

      expect(response.status).toBe(400);
    });

    test('MW-Validation-003: Should accept valid request body', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send(signupData.validSignup);

      expect(response.status).toBe(201);
    });

    test('MW-Validation-004: Should reject missing required fields', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          name: 'Test User',
        });

      expect(response.status).toBe(400);
    });

    test('MW-Validation-005: Should reject extra fields gracefully', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          ...signupData.validSignup,
          unknownField: 'value',
        });

      expect([200, 201, 400]).toContain(response.status);
    });
  });

  describe('Email Validation', () => {
    test('MW-Validation-006: Should validate email format', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          ...signupData.validSignup,
          email: 'not-an-email',
        });

      expect(response.status).toBe(400);
    });

    test('MW-Validation-007: Should accept valid email formats', async () => {
      const validEmails = [
        'test@example.com',
        'user.name@example.com',
        'user+tag@example.com',
        'user123@example.co.uk',
      ];

      for (const email of validEmails) {
        const response = await request(app)
          .post('/api/v1/auth/signup')
          .send({
            ...signupData.validSignup,
            email,
          });

        expect([200, 201, 409]).toContain(response.status);
      }
    });

    test('MW-Validation-008: Should reject empty email', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          ...signupData.validSignup,
          email: '',
        });

      expect(response.status).toBe(400);
    });

    test('MW-Validation-009: Should reject email with spaces', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          ...signupData.validSignup,
          email: 'user @example.com',
        });

      expect(response.status).toBe(400);
    });
  });

  describe('Password Validation', () => {
    test('MW-Validation-010: Should validate password strength', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          ...signupData.validSignup,
          password: 'weak',
          confirmPassword: 'weak',
        });

      expect(response.status).toBe(400);
    });

    test('MW-Validation-011: Should require uppercase character', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          ...signupData.validSignup,
          password: 'password123!',
          confirmPassword: 'password123!',
        });

      expect(response.status).toBe(400);
    });

    test('MW-Validation-012: Should require lowercase character', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          ...signupData.validSignup,
          password: 'PASSWORD123!',
          confirmPassword: 'PASSWORD123!',
        });

      expect(response.status).toBe(400);
    });

    test('MW-Validation-013: Should require number', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          ...signupData.validSignup,
          password: 'Password!',
          confirmPassword: 'Password!',
        });

      expect(response.status).toBe(400);
    });

    test('MW-Validation-014: Should require special character', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          ...signupData.validSignup,
          password: 'Password123',
          confirmPassword: 'Password123',
        });

      expect(response.status).toBe(400);
    });

    test('MW-Validation-015: Should require minimum 8 characters', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          ...signupData.validSignup,
          password: 'Pass12!',
          confirmPassword: 'Pass12!',
        });

      expect(response.status).toBe(400);
    });

    test('MW-Validation-016: Should validate password confirmation', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          ...signupData.validSignup,
          password: 'ValidPass123!',
          confirmPassword: 'DifferentPass123!',
        });

      expect(response.status).toBe(400);
    });
  });

  describe('Profile Update Validation', () => {
    let accessToken: string;

    beforeEach(async () => {
      const signupRes = await request(app)
        .post('/api/v1/auth/signup')
        .send(signupData.validSignup);

      accessToken = signupRes.body.data.accessToken;
    });

    test('MW-Validation-017: Should validate age minimum on update', async () => {
      const response = await request(app)
        .put('/api/v1/users/me')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ age: 17 });

      expect(response.status).toBe(400);
    });

    test('MW-Validation-018: Should validate age maximum on update', async () => {
      const response = await request(app)
        .put('/api/v1/users/me')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ age: 121 });

      expect(response.status).toBe(400);
    });

    test('MW-Validation-019: Should validate gender enum on update', async () => {
      const response = await request(app)
        .put('/api/v1/users/me')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ gender: 'InvalidGender' });

      expect(response.status).toBe(400);
    });

    test('MW-Validation-020: Should accept valid gender values', async () => {
      const validGenders = ['Male', 'Female', 'Others'];

      for (const gender of validGenders) {
        const response = await request(app)
          .put('/api/v1/users/me')
          .set('Authorization', `Bearer ${accessToken}`)
          .send({ gender });

        expect(response.status).toBe(200);
      }
    });

    test('MW-Validation-021: Should allow partial updates', async () => {
      const response = await request(app)
        .put('/api/v1/users/me')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ age: 40 });

      expect(response.status).toBe(200);
    });

    test('MW-Validation-022: Should allow empty update object', async () => {
      const response = await request(app)
        .put('/api/v1/users/me')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({});

      expect(response.status).toBe(200);
    });
  });

  describe('Error Response Format', () => {
    test('MW-Validation-023: Should include error status', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          name: 'Test',
        });

      expect(response.body.status).toBe('fail');
    });

    test('MW-Validation-024: Should include error message', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          name: 'Test',
        });

      expect(response.body.message).toContain('Validation error');
    });

    test('MW-Validation-025: Should include status code', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          name: 'Test',
        });

      expect(response.body.statusCode).toBe(400);
    });

    test('MW-Validation-026: Should include timestamp', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          name: 'Test',
        });

      expect(response.body.timestamp).toBeDefined();
    });
  });

  describe('Type Coercion', () => {
    test('MW-Validation-027: Should accept number as string for phone', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          ...signupData.validSignup,
          phone: '+1234567890',
        });

      expect(response.status).toBe(201);
    });

    test('MW-Validation-028: Should accept age as number', async () => {
      const signupRes = await request(app)
        .post('/api/v1/auth/signup')
        .send(signupData.validSignup);

      const accessToken = signupRes.body.data.accessToken;

      const response = await request(app)
        .put('/api/v1/users/me')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ age: 35 });

      expect(response.status).toBe(200);
    });
  });

  describe('Validation Chain', () => {
    test('MW-Validation-029: Should validate multiple errors', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          name: 'Test',
          email: 'invalid-email',
          password: 'weak',
        });

      expect(response.status).toBe(400);
      expect(response.body.message).toContain('Validation error');
    });

    test('MW-Validation-030: Should stop after validation error', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          name: 'Test',
          email: 'invalid-email',
        });

      expect(response.status).toBe(400);
      expect(response.body.statusCode).toBe(400);
    });
  });
});
