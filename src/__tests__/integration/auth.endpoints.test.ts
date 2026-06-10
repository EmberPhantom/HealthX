import request from 'supertest';
import app from '../../app';
import User from '../../models/User';
import Patient from '../../models/Patient';
import LoginAttempt from '../../models/LoginAttempt';
import AuditLog from '../../models/AuditLog';
import { testUsers, generateTestTokens, signupData, loginCredentials } from '../fixtures/test.fixtures';

jest.mock('google-auth-library', () => {
  return {
    OAuth2Client: jest.fn().mockImplementation(() => {
      return {
        verifyIdToken: jest.fn().mockResolvedValue({
          getPayload: () => ({
            sub: 'google-user-id-123',
            email: 'googleuser@example.com',
            name: 'Google User',
            picture: 'https://google.com/avatar.png',
          }),
        }),
      };
    }),
  };
});

describe('Auth Endpoints Integration Tests', () => {
  afterEach(async () => {
    await User.deleteMany({});
    await Patient.deleteMany({});
    await LoginAttempt.deleteMany({});
    await AuditLog.deleteMany({});
  });

  describe('POST /api/v1/auth/signup', () => {
    test('INT-Auth-001: Should signup successfully and return tokens', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send(signupData.validSignup);

      expect(response.status).toBe(201);
      expect(response.body.status).toBe('success');
      expect(response.body.data.accessToken).toBeDefined();
      expect(response.body.data.refreshToken).toBeDefined();
      expect(response.body.data.user.email).toBe(signupData.validSignup.email);
    });

    test('INT-Auth-002: Should create user and patient on signup', async () => {
      await request(app)
        .post('/api/v1/auth/signup')
        .send(signupData.validSignup);

      const user = await User.findOne({ email: signupData.validSignup.email });
      const patient = await Patient.findOne({ userId: user!._id });

      expect(user).toBeDefined();
      expect(patient).toBeDefined();
    });

    test('INT-Auth-003: Should reject duplicate email with 409', async () => {
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
      expect(response.body.status).toBe('fail');
    });

    test('INT-Auth-004: Should validate email format', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          ...signupData.validSignup,
          email: 'invalid-email',
        });

      expect(response.status).toBe(400);
      expect(response.body.message).toContain('Validation error');
    });

    test('INT-Auth-005: Should validate password strength', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          ...signupData.validSignup,
          password: 'weak',
          confirmPassword: 'weak',
        });

      expect(response.status).toBe(400);
    });

    test('INT-Auth-006: Should reject mismatched passwords', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send(signupData.mismatchedPasswords);

      expect(response.status).toBe(400);
    });

    test('INT-Auth-007: Should require all fields', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          name: signupData.validSignup.name,
          email: signupData.validSignup.email,
        });

      expect(response.status).toBe(400);
    });

    test('INT-Auth-008: Should return correct user data', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send(signupData.validSignup);

      expect(response.body.data.user.id).toBeDefined();
      expect(response.body.data.user.name).toBe(signupData.validSignup.name);
      expect(response.body.data.user.role).toBe('user');
    });
  });

  describe('POST /api/v1/auth/login', () => {
    beforeEach(async () => {
      await request(app)
        .post('/api/v1/auth/signup')
        .send({
          ...testUsers.validUser,
          confirmPassword: testUsers.validUser.password,
        });
    });

    test('INT-Auth-009: Should login successfully', async () => {
      const response = await request(app)
        .post('/api/v1/auth/login')
        .send(loginCredentials.validLogin);

      expect(response.status).toBe(200);
      expect(response.body.status).toBe('success');
      expect(response.body.data.accessToken).toBeDefined();
      expect(response.body.data.refreshToken).toBeDefined();
    });

    test('INT-Auth-010: Should reject invalid email', async () => {
      const response = await request(app)
        .post('/api/v1/auth/login')
        .send(loginCredentials.nonExistentUser);

      expect(response.status).toBe(401);
      expect(response.body.message).toContain('Invalid email or password');
    });

    test('INT-Auth-011: Should reject wrong password', async () => {
      const response = await request(app)
        .post('/api/v1/auth/login')
        .send(loginCredentials.wrongPassword);

      expect(response.status).toBe(401);
    });

    test('INT-Auth-012: Should require email and password', async () => {
      const response = await request(app)
        .post('/api/v1/auth/login')
        .send({ email: loginCredentials.validLogin.email });

      expect(response.status).toBe(400);
    });

    test('INT-Auth-013: Should return user data on login', async () => {
      const response = await request(app)
        .post('/api/v1/auth/login')
        .send(loginCredentials.validLogin);

      expect(response.body.data.user).toBeDefined();
      expect(response.body.data.user.email).toBe(testUsers.validUser.email);
    });
  });

  describe('POST /api/v1/auth/refresh', () => {
    let refreshToken: string;

    beforeEach(async () => {
      const signupRes = await request(app)
        .post('/api/v1/auth/signup')
        .send(signupData.validSignup);

      refreshToken = signupRes.body.data.refreshToken;
    });

    test('INT-Auth-014: Should refresh token successfully', async () => {
      const response = await request(app)
        .post('/api/v1/auth/refresh')
        .send({ refreshToken });

      expect(response.status).toBe(200);
      expect(response.body.data.accessToken).toBeDefined();
      expect(response.body.data.expiresAt).toBeDefined();
    });

    test('INT-Auth-015: Should return new token', async () => {
      const res1 = await request(app)
        .post('/api/v1/auth/refresh')
        .send({ refreshToken });

      expect(res1.body.data.accessToken).not.toBe(refreshToken);
    });

    test('INT-Auth-016: Should reject invalid token', async () => {
      const response = await request(app)
        .post('/api/v1/auth/refresh')
        .send({ refreshToken: 'invalid.token.here' });

      expect(response.status).toBe(401);
    });

    test('INT-Auth-017: Should require refresh token', async () => {
      const response = await request(app)
        .post('/api/v1/auth/refresh')
        .send({});

      expect(response.status).toBe(400);
    });
  });

  describe('POST /api/v1/auth/logout', () => {
    let accessToken: string;
    let refreshToken: string;

    beforeEach(async () => {
      const signupRes = await request(app)
        .post('/api/v1/auth/signup')
        .send(signupData.validSignup);

      accessToken = signupRes.body.data.accessToken;
      refreshToken = signupRes.body.data.refreshToken;
    });

    test('INT-Auth-018: Should logout successfully', async () => {
      const response = await request(app)
        .post('/api/v1/auth/logout')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ refreshToken });

      expect(response.status).toBe(200);
      expect(response.body.message).toBe('Logout successful');
    });

    test('INT-Auth-019: Should require authentication', async () => {
      const response = await request(app)
        .post('/api/v1/auth/logout')
        .send({ refreshToken });

      expect(response.status).toBe(401);
    });

    test('INT-Auth-020: Should require refresh token', async () => {
      const response = await request(app)
        .post('/api/v1/auth/logout')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({});

      expect(response.status).toBe(400);
    });

    test('INT-Auth-021: Should blacklist token', async () => {
      await request(app)
        .post('/api/v1/auth/logout')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ refreshToken });

      // Try to refresh with blacklisted token
      const response = await request(app)
        .post('/api/v1/auth/refresh')
        .send({ refreshToken });

      expect(response.status).toBe(401);
    });
  });

  describe('GET /api/v1/auth/me', () => {
    let accessToken: string;

    beforeEach(async () => {
      const signupRes = await request(app)
        .post('/api/v1/auth/signup')
        .send(signupData.validSignup);

      accessToken = signupRes.body.data.accessToken;
    });

    test('INT-Auth-022: Should get current user profile', async () => {
      const response = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(response.status).toBe(200);
      expect(response.body.data.email).toBe(signupData.validSignup.email);
    });

    test('INT-Auth-023: Should require authentication', async () => {
      const response = await request(app).get('/api/v1/auth/me');

      expect(response.status).toBe(401);
    });

    test('INT-Auth-024: Should reject invalid token', async () => {
      const response = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', 'Bearer invalid.token');

      expect(response.status).toBe(401);
    });

    test('INT-Auth-025: Should return user details', async () => {
      const response = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(response.body.data.name).toBe(signupData.validSignup.name);
      expect(response.body.data.role).toBe('user');
      expect(response.body.data.isEmailVerified).toBeDefined();
    });
  });

  describe('PUT /api/v1/auth/me', () => {
    let accessToken: string;

    beforeEach(async () => {
      const signupRes = await request(app)
        .post('/api/v1/auth/signup')
        .send(signupData.validSignup);

      accessToken = signupRes.body.data.accessToken;
    });

    test('INT-Auth-026: Should update user profile', async () => {
      const response = await request(app)
        .put('/api/v1/auth/me')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          name: 'Updated Name',
          age: 35,
        });

      expect(response.status).toBe(200);
      expect(response.body.data.name).toBe('Updated Name');
      expect(response.body.data.age).toBe(35);
    });

    test('INT-Auth-027: Should validate update data', async () => {
      const response = await request(app)
        .put('/api/v1/auth/me')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          age: 12, // Below minimum (13)
        });

      expect(response.status).toBe(400);
    });

    test('INT-Auth-028: Should require authentication', async () => {
      const response = await request(app)
        .put('/api/v1/auth/me')
        .send({ name: 'Updated' });

      expect(response.status).toBe(401);
    });

    test('INT-Auth-029: Should allow partial updates', async () => {
      const response = await request(app)
        .put('/api/v1/auth/me')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ age: 40 });

      expect(response.status).toBe(200);
      expect(response.body.data.age).toBe(40);
      expect(response.body.data.name).toBe(signupData.validSignup.name);
    });
  });

  describe('POST /api/v1/auth/google', () => {
    test('INT-Auth-030: Should return placeholder for Google endpoint', async () => {
      const response = await request(app)
        .post('/api/v1/auth/google')
        .send({ idToken: 'mock-google-token' });

      expect(response.status).toBe(200);
      expect(response.body.message).toContain('Google');
    });

    test('INT-Auth-031: Should require token', async () => {
      const response = await request(app)
        .post('/api/v1/auth/google')
        .send({});

      expect(response.status).toBe(400);
    });
  });

  describe('POST /api/v1/auth/me/upload-picture', () => {
    let accessToken: string;

    beforeEach(async () => {
      const signupRes = await request(app)
        .post('/api/v1/auth/signup')
        .send(signupData.validSignup);

      accessToken = signupRes.body.data.accessToken;
    });

    test('INT-Auth-032: Should return placeholder for picture upload', async () => {
      const pngBuffer = Buffer.from(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
        'base64'
      );
      const response = await request(app)
        .post('/api/v1/auth/me/upload-picture')
        .set('Authorization', `Bearer ${accessToken}`)
        .attach('file', pngBuffer, 'avatar.png');

      expect(response.status).toBe(200);
      expect(response.body.message).toContain('upload');
    });

    test('INT-Auth-033: Should require authentication', async () => {
      const response = await request(app)
        .post('/api/v1/auth/me/upload-picture');

      expect(response.status).toBe(401);
    });
  });
});
