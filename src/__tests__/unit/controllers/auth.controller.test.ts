import request from 'supertest';
import app from '../../../app';
import User from '../../../models/User';
import Patient from '../../../models/Patient';
import LoginAttempt from '../../../models/LoginAttempt';
import AuditLog from '../../../models/AuditLog';
import { authService } from '../../../services/auth.service';

// Mock Google OAuth2 client
jest.mock('google-auth-library', () => ({
  OAuth2Client: jest.fn().mockImplementation(() => ({
    verifyIdToken: jest.fn().mockResolvedValue({
      getPayload: () => ({
        sub: 'google-id-123',
        email: 'google.user@example.com',
        name: 'Google User',
        picture: 'https://google.com/avatar.png',
      }),
    }),
  })),
}));

// Mock password reset service to avoid actual email sending
jest.mock('../../../services/password-reset.service', () => ({
  passwordResetService: {
    requestReset: jest.fn().mockResolvedValue({ message: 'Reset email sent' }),
    resetPassword: jest.fn().mockResolvedValue({ message: 'Password reset successfully' }),
  },
}));

describe('Auth Controller Tests', () => {
  afterEach(async () => {
    await User.deleteMany({});
    await Patient.deleteMany({});
    await LoginAttempt.deleteMany({});
    await AuditLog.deleteMany({});
  });

  afterAll(async () => {
    await User.deleteMany({});
    await Patient.deleteMany({});
    await LoginAttempt.deleteMany({});
    await AuditLog.deleteMany({});
  });

  describe('POST /api/v1/auth/signup', () => {
    it('should signup a new user and return tokens', async () => {
      const res = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          name: 'Test User',
          email: 'test@example.com',
          password: 'SecurePass123!',
          phone: '+1234567890',
          confirmPassword: 'SecurePass123!',
        });

      expect(res.status).toBe(201);
      expect(res.body.status).toBe('success');
      expect(res.body.data).toHaveProperty('accessToken');
      expect(res.body.data).toHaveProperty('refreshToken');
      expect(res.body.data.user.email).toBe('test@example.com');
    });

    it('should create patient profile on signup', async () => {
      await request(app)
        .post('/api/v1/auth/signup')
        .send({
          name: 'Test User',
          email: 'patienttest@example.com',
          password: 'SecurePass123!',
          phone: '+1234567890',
        });

      const user = await User.findOne({ email: 'patienttest@example.com' });
      const patient = await Patient.findOne({ userId: user!._id });
      expect(patient).toBeDefined();
    });

    it('should reject duplicate email with 409', async () => {
      await request(app)
        .post('/api/v1/auth/signup')
        .send({
          name: 'First User',
          email: 'duplicate@example.com',
          password: 'SecurePass123!',
          phone: '+1234567890',
        });

      const res = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          name: 'Second User',
          email: 'duplicate@example.com',
          password: 'SecurePass123!',
          phone: '+0987654321',
        });

      expect(res.status).toBe(409);
      expect(res.body.status).toBe('fail');
    });

    it('should reject weak password', async () => {
      const res = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          name: 'Test User',
          email: 'weak@example.com',
          password: 'weak',
          phone: '+1234567890',
        });

      expect(res.status).toBe(400);
    });

    it('should reject mismatched passwords', async () => {
      const res = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          name: 'Test User',
          email: 'mismatch@example.com',
          password: 'SecurePass123!',
          confirmPassword: 'DifferentPass123!',
        });

      expect(res.status).toBe(400);
    });

    it('should reject invalid email', async () => {
      const res = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          name: 'Test User',
          email: 'not-an-email',
          password: 'SecurePass123!',
          phone: '+1234567890',
        });

      expect(res.status).toBe(400);
    });
  });

  describe('POST /api/v1/auth/login', () => {
    beforeEach(async () => {
      await authService.signup('Login User', 'login@example.com', 'SecurePass123!', '+1234567890');
    });

    it('should login successfully with valid credentials', async () => {
      const res = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: 'login@example.com',
          password: 'SecurePass123!',
        });

      expect(res.status).toBe(200);
      expect(res.body.status).toBe('success');
      expect(res.body.data).toHaveProperty('accessToken');
      expect(res.body.data).toHaveProperty('refreshToken');
      expect(res.body.data.user.email).toBe('login@example.com');
    });

    it('should reject wrong password', async () => {
      const res = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: 'login@example.com',
          password: 'WrongPassword123!',
        });

      expect(res.status).toBe(401);
    });

    it('should reject non-existent email', async () => {
      const res = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: 'nonexistent@example.com',
          password: 'SecurePass123!',
        });

      expect(res.status).toBe(401);
    });

    it('should reject missing password', async () => {
      const res = await request(app)
        .post('/api/v1/auth/login')
        .send({ email: 'login@example.com' });

      expect(res.status).toBe(400);
    });
  });

  describe('POST /api/v1/auth/google', () => {
    it('should authenticate with valid Google token', async () => {
      const res = await request(app)
        .post('/api/v1/auth/google')
        .send({ idToken: 'valid-google-token' });

      expect(res.status).toBe(200);
      expect(res.body.status).toBe('success');
      expect(res.body.data).toHaveProperty('accessToken');
      expect(res.body.data.user.email).toBe('google.user@example.com');
    });

    it('should reject missing idToken', async () => {
      const res = await request(app)
        .post('/api/v1/auth/google')
        .send({});

      expect(res.status).toBe(400);
    });
  });

  describe('POST /api/v1/auth/refresh', () => {
    it('should refresh token with valid refresh token', async () => {
      const signupRes = await authService.signup('Refresh User', 'refresh@example.com', 'SecurePass123!', '+1234567890');

      const res = await request(app)
        .post('/api/v1/auth/refresh')
        .send({ refreshToken: signupRes.refreshToken });

      expect(res.status).toBe(200);
      expect(res.body.data).toHaveProperty('accessToken');
    });

    it('should reject missing refresh token', async () => {
      const res = await request(app)
        .post('/api/v1/auth/refresh')
        .send({});

      expect(res.status).toBe(400);
    });
  });

  describe('POST /api/v1/auth/logout', () => {
    it('should logout successfully', async () => {
      const signupRes = await authService.signup('Logout User', 'logout@example.com', 'SecurePass123!', '+1234567890');

      const res = await request(app)
        .post('/api/v1/auth/logout')
        .set('Authorization', `Bearer ${signupRes.accessToken}`)
        .send({ refreshToken: signupRes.refreshToken });

      expect(res.status).toBe(200);
      expect(res.body.status).toBe('success');
    });
  });

  describe('POST /api/v1/auth/forgot-password', () => {
    it('should send password reset email', async () => {
      const res = await request(app)
        .post('/api/v1/auth/forgot-password')
        .send({ email: 'anyuser@example.com' });

      // Always returns 200 to prevent email enumeration
      expect(res.status).toBe(200);
      expect(res.body.status).toBe('success');
    });

    it('should reject invalid email format', async () => {
      const res = await request(app)
        .post('/api/v1/auth/forgot-password')
        .send({ email: 'invalid' });

      expect(res.status).toBe(400);
    });
  });

  describe('POST /api/v1/auth/reset-password', () => {
    it('should reset password with valid token', async () => {
      const res = await request(app)
        .post('/api/v1/auth/reset-password')
        .send({
          token: 'valid-reset-token',
          password: 'NewSecurePass123!',
        });

      expect(res.status).toBe(200);
      expect(res.body.status).toBe('success');
    });

    it('should reject weak new password', async () => {
      const res = await request(app)
        .post('/api/v1/auth/reset-password')
        .send({
          token: 'valid-reset-token',
          password: 'weak',
        });

      expect(res.status).toBe(400);
    });
  });

  describe('GET /api/v1/auth/me', () => {
    it('should return current user profile', async () => {
      const signupRes = await authService.signup('Me User', 'me@example.com', 'SecurePass123!', '+1234567890');

      const res = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${signupRes.accessToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.email).toBe('me@example.com');
    });

    it('should reject without auth', async () => {
      const res = await request(app).get('/api/v1/auth/me');

      expect(res.status).toBe(401);
    });
  });
});
