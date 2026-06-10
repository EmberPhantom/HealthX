import request from 'supertest';
import app from '../../app';
import User from '../../models/User';
import PasswordReset from '../../models/PasswordReset';
import { signupData } from '../fixtures/test.fixtures';

describe('Password Reset Integration Tests', () => {
  let userId: string;
  const userEmail = signupData.validSignup.email;
  const userPassword = signupData.validSignup.password;

  beforeEach(async () => {
    await User.deleteMany({});
    await PasswordReset.deleteMany({});

    // Register a user
    const signupRes = await request(app)
      .post('/api/v1/auth/signup')
      .send(signupData.validSignup);
    
    userId = signupRes.body.data.user.id;
  });

  afterAll(async () => {
    await User.deleteMany({});
    await PasswordReset.deleteMany({});
  });

  describe('POST /api/v1/auth/forgot-password', () => {
    test('INT-Reset-001: Should return 200 for registered email and create token', async () => {
      const response = await request(app)
        .post('/api/v1/auth/forgot-password')
        .send({ email: userEmail });

      expect(response.status).toBe(200);
      expect(response.body.status).toBe('success');
      expect(response.body.message).toContain('password reset link has been sent');

      const tokenRecord = await PasswordReset.findOne({ email: userEmail });
      expect(tokenRecord).toBeDefined();
      expect(tokenRecord?.isUsed).toBe(false);
      expect(tokenRecord?.token).toBeDefined();
    });

    test('INT-Reset-002: Should return 200 for non-existent email (no enumeration) and not create token', async () => {
      const response = await request(app)
        .post('/api/v1/auth/forgot-password')
        .send({ email: 'nonexistent@example.com' });

      expect(response.status).toBe(200);
      expect(response.body.status).toBe('success');

      const tokenRecord = await PasswordReset.findOne({ email: 'nonexistent@example.com' });
      expect(tokenRecord).toBeNull();
    });

    test('INT-Reset-003: Should reject invalid email format with 400', async () => {
      const response = await request(app)
        .post('/api/v1/auth/forgot-password')
        .send({ email: 'not-an-email' });

      expect(response.status).toBe(400);
      expect(response.body.message).toContain('Validation error');
    });
  });

  describe('POST /api/v1/auth/reset-password', () => {
    let resetToken: string;

    beforeEach(async () => {
      await request(app)
        .post('/api/v1/auth/forgot-password')
        .send({ email: userEmail });

      const tokenRecord = await PasswordReset.findOne({ email: userEmail });
      resetToken = tokenRecord!.token;
    });

    test('INT-Reset-004: Should reset password successfully with valid token and allow login', async () => {
      const newPassword = 'NewSecurePassword123!';
      const response = await request(app)
        .post('/api/v1/auth/reset-password')
        .send({
          token: resetToken,
          password: newPassword,
        });

      expect(response.status).toBe(200);
      expect(response.body.status).toBe('success');
      expect(response.body.message).toContain('reset successfully');

      // Verify token is marked used
      const tokenRecord = await PasswordReset.findOne({ token: resetToken });
      expect(tokenRecord?.isUsed).toBe(true);
      expect(tokenRecord?.usedAt).toBeDefined();

      // Verify we can login with new password
      const loginRes = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: userEmail,
          password: newPassword,
        });

      expect(loginRes.status).toBe(200);
      expect(loginRes.body.data.accessToken).toBeDefined();
    });

    test('INT-Reset-005: Should reject reset password if password strength is weak', async () => {
      const response = await request(app)
        .post('/api/v1/auth/reset-password')
        .send({
          token: resetToken,
          password: 'weak',
        });

      expect(response.status).toBe(400);
    });

    test('INT-Reset-006: Should reject already-used token', async () => {
      const newPassword = 'NewSecurePassword123!';
      
      // Use it first
      await request(app)
        .post('/api/v1/auth/reset-password')
        .send({
          token: resetToken,
          password: newPassword,
        });

      // Try to use it again
      const response = await request(app)
        .post('/api/v1/auth/reset-password')
        .send({
          token: resetToken,
          password: 'AnotherPassword456!',
        });

      expect(response.status).toBe(400);
      expect(response.body.message).toContain('Invalid or expired password reset token');
    });

    test('INT-Reset-007: Should reject expired token', async () => {
      // Manually create an expired token record
      const expiredToken = 'expired-token-xyz';
      await PasswordReset.create({
        userId,
        email: userEmail,
        token: expiredToken,
        expiresAt: new Date(Date.now() - 1000), // Expired 1s ago
      });

      const response = await request(app)
        .post('/api/v1/auth/reset-password')
        .send({
          token: expiredToken,
          password: 'AnotherPassword456!',
        });

      expect(response.status).toBe(400);
      expect(response.body.message).toContain('Invalid or expired password reset token');
    });
  });
});
