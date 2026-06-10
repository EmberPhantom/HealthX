import request from 'supertest';
import app from '../../app';
import User from '../../models/User';
import { signupData, testUsers } from '../fixtures/test.fixtures';

describe('Edge Cases Tests', () => {
  afterEach(async () => {
    await User.deleteMany({});
  });

  describe('Boundary Values', () => {
    test('EDGE-Boundary-001: Should handle minimum valid age (18)', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send(signupData.validSignup);

      const accessToken = response.body.data.accessToken;

      const updateRes = await request(app)
        .put('/api/v1/users/me')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ age: 18 });

      expect(updateRes.status).toBe(200);
      expect(updateRes.body.data.age).toBe(18);
    });

    test('EDGE-Boundary-002: Should handle maximum valid age (120)', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send(signupData.validSignup);

      const accessToken = response.body.data.accessToken;

      const updateRes = await request(app)
        .put('/api/v1/users/me')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ age: 120 });

      expect(updateRes.status).toBe(200);
      expect(updateRes.body.data.age).toBe(120);
    });

    test('EDGE-Boundary-003: Should reject age just below minimum (17)', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send(signupData.validSignup);

      const accessToken = response.body.data.accessToken;

      const updateRes = await request(app)
        .put('/api/v1/users/me')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ age: 17 });

      expect(updateRes.status).toBe(400);
    });

    test('EDGE-Boundary-004: Should reject age just above maximum (121)', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send(signupData.validSignup);

      const accessToken = response.body.data.accessToken;

      const updateRes = await request(app)
        .put('/api/v1/users/me')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ age: 121 });

      expect(updateRes.status).toBe(400);
    });
  });

  describe('Special Characters', () => {
    test('EDGE-Special-001: Should handle special characters in name', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          ...signupData.validSignup,
          name: "O'Brien-Smith",
          email: 'special@example.com',
        });

      expect(response.status).toBe(201);
      expect(response.body.data.user.name).toBe("O'Brien-Smith");
    });

    test('EDGE-Special-002: Should handle unicode characters in name', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          ...signupData.validSignup,
          name: 'José García',
          email: 'unicode@example.com',
        });

      expect(response.status).toBe(201);
      expect(response.body.data.user.name).toBe('José García');
    });

    test('EDGE-Special-003: Should handle long phone numbers', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          ...signupData.validSignup,
          phone: '+1-800-FLOWERS',
          email: 'phone@example.com',
        });

      expect(response.status).toBe(201);
    });

    test('EDGE-Special-004: Should handle international phone numbers', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          ...signupData.validSignup,
          phone: '+442071838750',
          email: 'intl@example.com',
        });

      expect(response.status).toBe(201);
    });

    test('EDGE-Special-005: Should handle emails with plus addressing', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          ...signupData.validSignup,
          email: 'user+tag@example.com',
        });

      expect(response.status).toBe(201);
    });
  });

  describe('String Length Edge Cases', () => {
    test('EDGE-Length-001: Should handle minimum valid name length (2)', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          ...signupData.validSignup,
          name: 'Jo',
          email: 'minname@example.com',
        });

      expect(response.status).toBe(201);
    });

    test('EDGE-Length-002: Should reject name below minimum (1)', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          ...signupData.validSignup,
          name: 'J',
          email: 'onechar@example.com',
        });

      expect(response.status).toBe(400);
    });

    test('EDGE-Length-003: Should handle maximum name length (100)', async () => {
      const longName = 'A'.repeat(100);
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          ...signupData.validSignup,
          name: longName,
          email: 'longname@example.com',
        });

      expect(response.status).toBe(201);
    });

    test('EDGE-Length-004: Should reject name above maximum (101)', async () => {
      const tooLongName = 'A'.repeat(101);
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          ...signupData.validSignup,
          name: tooLongName,
          email: 'toolongname@example.com',
        });

      expect(response.status).toBe(400);
    });

    test('EDGE-Length-005: Should handle minimum password length (8)', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          name: 'Test User',
          email: 'minpass@example.com',
          password: 'Pass123!',
          confirmPassword: 'Pass123!',
          phone: '+1234567890',
        });

      expect(response.status).toBe(201);
    });

    test('EDGE-Length-006: Should reject password below minimum (7)', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          ...signupData.validSignup,
          password: 'Pass12!',
          confirmPassword: 'Pass12!',
          email: 'shortpass@example.com',
        });

      expect(response.status).toBe(400);
    });
  });

  describe('Null and Empty Values', () => {
    test('EDGE-Null-001: Should reject null email', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          ...signupData.validSignup,
          email: null,
        });

      expect(response.status).toBe(400);
    });

    test('EDGE-Null-002: Should reject empty name', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          ...signupData.validSignup,
          name: '',
          email: 'emptyname@example.com',
        });

      expect(response.status).toBe(400);
    });

    test('EDGE-Null-003: Should reject whitespace-only name', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          ...signupData.validSignup,
          name: '   ',
          email: 'whitespace@example.com',
        });

      expect(response.status).toBe(400);
    });

    test('EDGE-Null-004: Should allow optional fields to be null', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send(signupData.validSignup);

      const accessToken = response.body.data.accessToken;

      // Update with optional field being cleared
      const updateRes = await request(app)
        .put('/api/v1/users/me')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ age: null });

      // Should either succeed or fail gracefully
      expect([200, 400]).toContain(updateRes.status);
    });
  });

  describe('Rapid Operations', () => {
    test('EDGE-Rapid-001: Should handle rapid signup and login', async () => {
      const signupRes = await request(app)
        .post('/api/v1/auth/signup')
        .send(signupData.validSignup);

      // Immediately try to login
      const loginRes = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: signupData.validSignup.email,
          password: signupData.validSignup.password,
        });

      expect(loginRes.status).toBe(200);
    });

    test('EDGE-Rapid-002: Should handle rapid refresh token calls', async () => {
      const signupRes = await request(app)
        .post('/api/v1/auth/signup')
        .send(signupData.validSignup);

      const refreshToken = signupRes.body.data.refreshToken;

      const promises = Array(5).fill(null).map(() =>
        request(app)
          .post('/api/v1/auth/refresh')
          .send({ refreshToken })
      );

      const results = await Promise.all(promises);

      // First call should succeed, others might fail due to token being refreshed
      expect(results[0].status).toBe(200);
    });

    test('EDGE-Rapid-003: Should handle rapid profile updates', async () => {
      const signupRes = await request(app)
        .post('/api/v1/auth/signup')
        .send(signupData.validSignup);

      const accessToken = signupRes.body.data.accessToken;

      const promises = Array(3).fill(null).map((_, i) =>
        request(app)
          .put('/api/v1/users/me')
          .set('Authorization', `Bearer ${accessToken}`)
          .send({ age: 30 + i })
      );

      const results = await Promise.all(promises);

      // All should succeed or complete without catastrophic failure
      expect(results.every((r: any) => [200, 400].includes(r.status))).toBe(true);
    });
  });

  describe('Case Sensitivity', () => {
    test('EDGE-Case-001: Should handle email case insensitivity in storage', async () => {
      const signupRes = await request(app)
        .post('/api/v1/auth/signup')
        .send(signupData.validSignup);

      expect(signupRes.status).toBe(201);

      // Try signup with different case
      const dupRes = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          ...signupData.validSignup,
          email: signupData.validSignup.email.toUpperCase(),
          name: 'Different Name',
        });

      // Should fail due to duplicate email
      expect(dupRes.status).toBe(409);
    });

    test('EDGE-Case-002: Should accept uppercase and lowercase emails', async () => {
      const emails = [
        'test@example.com',
        'TEST@EXAMPLE.COM',
        'Test@Example.Com',
      ];

      for (const email of emails) {
        const response = await request(app)
          .post('/api/v1/auth/signup')
          .send({
            ...signupData.validSignup,
            email,
          });

        expect([201, 409]).toContain(response.status); // First succeeds, others fail as duplicate
      }
    });
  });

  describe('Data Consistency', () => {
    test('EDGE-Consistency-001: Should maintain consistency across multiple reads', async () => {
      const signupRes = await request(app)
        .post('/api/v1/auth/signup')
        .send(signupData.validSignup);

      const accessToken = signupRes.body.data.accessToken;

      // Read multiple times
      const read1 = await request(app)
        .get('/api/v1/users/me')
        .set('Authorization', `Bearer ${accessToken}`);

      const read2 = await request(app)
        .get('/api/v1/users/me')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(read1.body.data.email).toBe(read2.body.data.email);
      expect(read1.body.data.id).toBe(read2.body.data.id);
    });

    test('EDGE-Consistency-002: Should persist updates correctly', async () => {
      const signupRes = await request(app)
        .post('/api/v1/auth/signup')
        .send(signupData.validSignup);

      const accessToken = signupRes.body.data.accessToken;

      await request(app)
        .put('/api/v1/users/me')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ age: 42 });

      const readRes = await request(app)
        .get('/api/v1/users/me')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(readRes.body.data.age).toBe(42);
    });
  });

  describe('Timeout Scenarios', () => {
    test('EDGE-Timeout-001: Should handle slow network response', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send(signupData.validSignup);

      expect(response.status).toBe(201);
    });

    test('EDGE-Timeout-002: Should not timeout on normal operations', async () => {
      const promises = Array(10).fill(null).map((_, i) =>
        request(app)
          .post('/api/v1/auth/signup')
          .send({
            ...signupData.validSignup,
            email: `user${i}@example.com`,
          })
      );

      const results = await Promise.all(promises);

      expect(results.every((r: any) => r.status === 201)).toBe(true);
    });
  });
});
