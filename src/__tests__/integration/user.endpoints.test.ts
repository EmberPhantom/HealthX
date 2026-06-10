import request from 'supertest';
import app from '../../app';
import User from '../../models/User';
import Patient from '../../models/Patient';
import { signupData, profileUpdates } from '../fixtures/test.fixtures';

describe('User Endpoints Integration Tests', () => {
  let accessToken: string;

  beforeEach(async () => {
    const signupRes = await request(app)
      .post('/api/v1/auth/signup')
      .send(signupData.validSignup);

    accessToken = signupRes.body.data.accessToken;
  });

  afterEach(async () => {
    await User.deleteMany({});
    await Patient.deleteMany({});
  });

  describe('GET /api/v1/users/me', () => {
    test('INT-User-001: Should get user profile', async () => {
      const response = await request(app)
        .get('/api/v1/users/me')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(response.status).toBe(200);
      expect(response.body.status).toBe('success');
      expect(response.body.data.email).toBe(signupData.validSignup.email);
    });

    test('INT-User-002: Should require authentication', async () => {
      const response = await request(app).get('/api/v1/users/me');

      expect(response.status).toBe(401);
    });

    test('INT-User-003: Should reject invalid token', async () => {
      const response = await request(app)
        .get('/api/v1/users/me')
        .set('Authorization', 'Bearer invalid.token');

      expect(response.status).toBe(401);
    });

    test('INT-User-004: Should return complete user data', async () => {
      const response = await request(app)
        .get('/api/v1/users/me')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(response.body.data).toHaveProperty('id');
      expect(response.body.data).toHaveProperty('name');
      expect(response.body.data).toHaveProperty('email');
      expect(response.body.data).toHaveProperty('phone');
      expect(response.body.data).toHaveProperty('role');
      expect(response.body.data).toHaveProperty('isEmailVerified');
    });

    test('INT-User-005: Should not expose password', async () => {
      const response = await request(app)
        .get('/api/v1/users/me')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(response.body.data.password).toBeUndefined();
    });
  });

  describe('PUT /api/v1/users/me', () => {
    test('INT-User-006: Should update user profile', async () => {
      const response = await request(app)
        .put('/api/v1/users/me')
        .set('Authorization', `Bearer ${accessToken}`)
        .send(profileUpdates.validUpdate);

      expect(response.status).toBe(200);
      expect(response.body.status).toBe('success');
      expect(response.body.data.name).toBe(profileUpdates.validUpdate.name);
    });

    test('INT-User-007: Should update all fields', async () => {
      const response = await request(app)
        .put('/api/v1/users/me')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          name: 'New Name',
          phone: '+9999999999',
          gender: 'Female',
          age: 50,
        });

      expect(response.status).toBe(200);
      expect(response.body.data.name).toBe('New Name');
      expect(response.body.data.phone).toBe('+9999999999');
      expect(response.body.data.gender).toBe('Female');
      expect(response.body.data.age).toBe(50);
    });

    test('INT-User-008: Should validate age minimum', async () => {
      const response = await request(app)
        .put('/api/v1/users/me')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ age: 12 });

      expect(response.status).toBe(400);
    });

    test('INT-User-009: Should validate age maximum', async () => {
      const response = await request(app)
        .put('/api/v1/users/me')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ age: 121 });

      expect(response.status).toBe(400);
    });

    test('INT-User-010: Should validate gender enum', async () => {
      const response = await request(app)
        .put('/api/v1/users/me')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ gender: 'InvalidGender' });

      expect(response.status).toBe(400);
    });

    test('INT-User-011: Should require authentication', async () => {
      const response = await request(app)
        .put('/api/v1/users/me')
        .send({ name: 'Updated' });

      expect(response.status).toBe(401);
    });

    test('INT-User-012: Should allow partial updates', async () => {
      const response = await request(app)
        .put('/api/v1/users/me')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ age: 45 });

      expect(response.status).toBe(200);
      expect(response.body.data.age).toBe(45);
      expect(response.body.data.name).toBe(signupData.validSignup.name);
    });

    test('INT-User-013: Should persist changes', async () => {
      await request(app)
        .put('/api/v1/users/me')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ name: 'Persisted Name' });

      const response = await request(app)
        .get('/api/v1/users/me')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(response.body.data.name).toBe('Persisted Name');
    });
  });

  describe('POST /api/v1/users/me/upload-picture', () => {
    test('INT-User-014: Should return placeholder for upload', async () => {
      const pngBuffer = Buffer.from(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
        'base64'
      );
      const response = await request(app)
        .post('/api/v1/users/me/upload-picture')
        .set('Authorization', `Bearer ${accessToken}`)
        .attach('file', pngBuffer, 'avatar.png');

      expect(response.status).toBe(200);
      expect(response.body.status).toBe('success');
      expect(response.body.message).toContain('upload');
    });

    test('INT-User-015: Should require authentication', async () => {
      const response = await request(app)
        .post('/api/v1/users/me/upload-picture');

      expect(response.status).toBe(401);
    });

    test('INT-User-016: Should reject invalid token', async () => {
      const response = await request(app)
        .post('/api/v1/users/me/upload-picture')
        .set('Authorization', 'Bearer invalid.token');

      expect(response.status).toBe(401);
    });
  });
});
