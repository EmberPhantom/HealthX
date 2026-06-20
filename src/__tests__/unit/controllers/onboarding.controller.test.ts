import request from 'supertest';
import app from '../../../app';
import User from '../../../models/User';
import Patient from '../../../models/Patient';
import EmailVerification from '../../../models/EmailVerification';
import { authService } from '../../../services/auth.service';

// Mock onboarding service to isolate controller behavior
jest.mock('../../../services/email.service', () => ({
  __esModule: true,
  default: {
    sendVerificationEmail: jest.fn().mockResolvedValue(true),
    sendPasswordResetEmail: jest.fn().mockResolvedValue(undefined),
  },
}));

describe('Onboarding Controller Tests', () => {
  let userId: string;
  let accessToken: string;

  beforeAll(async () => {
    await User.deleteMany({});
    await Patient.deleteMany({});
    await EmailVerification.deleteMany({});

    const user = await authService.signup('Onboarding Test User', 'onboarding.test@example.com', 'Password123!', '+19999999992');
    userId = user.user.id;
    accessToken = user.accessToken;
  });

  afterAll(async () => {
    await User.deleteMany({});
    await Patient.deleteMany({});
    await EmailVerification.deleteMany({});
  });

  describe('POST /api/v1/onboarding/verify-email', () => {
    it('should reject missing token', async () => {
      const res = await request(app)
        .post('/api/v1/onboarding/verify-email')
        .send({});

      expect(res.status).toBe(400);
    });
  });

  describe('POST /api/v1/onboarding/resend-verification', () => {
    it('should resend verification email', async () => {
      const res = await request(app)
        .post('/api/v1/onboarding/resend-verification')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
      expect(res.body.status).toBe('success');
    });

    it('should reject without auth', async () => {
      const res = await request(app)
        .post('/api/v1/onboarding/resend-verification');

      expect(res.status).toBe(401);
    });
  });

  describe('POST /api/v1/onboarding/complete', () => {
    beforeEach(async () => {
      await Patient.deleteMany({});
    });

    it('should complete onboarding with valid data', async () => {
      const res = await request(app)
        .post('/api/v1/onboarding/complete')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          medicalHistory: 'None',
          allergies: 'None',
          medications: 'None',
          emergencyContactName: 'Jane Doe',
          emergencyContactPhone: '+1234567890',
          wellnessGoals: ['exercise', 'diet'],
          activityLevel: 2,
          gender: 'Male',
        });

      expect(res.status).toBe(200);
      expect(res.body.status).toBe('success');
    });

    it('should reject without auth', async () => {
      const res = await request(app)
        .post('/api/v1/onboarding/complete')
        .send({ gender: 'Male' });

      expect(res.status).toBe(401);
    });
  });

  describe('GET /api/v1/onboarding/status', () => {
    it('should return onboarding status for authenticated user', async () => {
      const res = await request(app)
        .get('/api/v1/onboarding/status')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
      expect(res.body.status).toBe('success');
      expect(res.body.data).toHaveProperty('profileCompleted');
      expect(res.body.data).toHaveProperty('isEmailVerified');
    });

    it('should reject without auth', async () => {
      const res = await request(app).get('/api/v1/onboarding/status');

      expect(res.status).toBe(401);
    });
  });
});
