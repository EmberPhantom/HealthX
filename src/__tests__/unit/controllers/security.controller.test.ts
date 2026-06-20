import request from 'supertest';
import app from '../../../app';
import User from '../../../models/User';
import LoginAttempt from '../../../models/LoginAttempt';
import AuditLog from '../../../models/AuditLog';
import { authService } from '../../../services/auth.service';

describe('Security Controller Tests', () => {
  let userToken: string;
  let adminToken: string;

  beforeAll(async () => {
    await User.deleteMany({});
    await LoginAttempt.deleteMany({});
    await AuditLog.deleteMany({});

    const user = await authService.signup('Security User', 'security.user@example.com', 'Password123!', '+19999999983');
    userToken = user.accessToken;

    const admin = await authService.signup('Security Admin', 'security.admin@example.com', 'Password123!', '+19999999982');
    // Promote to admin
    await User.findByIdAndUpdate(admin.user.id, { role: 'admin' });
    // Get new token with admin role
    const adminLogin = await authService.login('security.admin@example.com', 'Password123!');
    adminToken = adminLogin.accessToken;
  });

  afterAll(async () => {
    await User.deleteMany({});
    await LoginAttempt.deleteMany({});
    await AuditLog.deleteMany({});
  });

  describe('GET /api/v1/security/csrf-token', () => {
    it('should return a CSRF token', async () => {
      const res = await request(app).get('/api/v1/security/csrf-token');

      expect(res.status).toBe(200);
      expect(res.body.status).toBe('success');
      expect(res.body.data).toHaveProperty('csrfToken');
    });
  });

  describe('GET /api/v1/security/login-history', () => {
    it('should return login history for authenticated user', async () => {
      const res = await request(app)
        .get('/api/v1/security/login-history')
        .set('Authorization', `Bearer ${userToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data).toHaveProperty('logins');
      expect(Array.isArray(res.body.data.logins)).toBe(true);
    });

    it('should reject without auth', async () => {
      const res = await request(app).get('/api/v1/security/login-history');

      expect(res.status).toBe(401);
    });
  });

  describe('GET /api/v1/security/suspicious-activity', () => {
    it('should reject for non-admin users', async () => {
      const res = await request(app)
        .get('/api/v1/security/suspicious-activity')
        .set('Authorization', `Bearer ${userToken}`)
        .query({ ip: '192.168.1.1' });

      expect(res.status).toBe(403);
    });

    it('should reject without ip query param', async () => {
      const res = await request(app)
        .get('/api/v1/security/suspicious-activity')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(res.status).toBe(400);
    });

    it('should return suspicious activity for admin', async () => {
      const res = await request(app)
        .get('/api/v1/security/suspicious-activity')
        .set('Authorization', `Bearer ${adminToken}`)
        .query({ ip: '192.168.1.1' });

      expect(res.status).toBe(200);
      expect(res.body.data.ipAddress).toBe('192.168.1.1');
    });
  });

  describe('POST /api/v1/security/clear-failed-attempts', () => {
    it('should reject for non-admin users', async () => {
      const res = await request(app)
        .post('/api/v1/security/clear-failed-attempts')
        .set('Authorization', `Bearer ${userToken}`)
        .send({ email: 'test@example.com' });

      expect(res.status).toBe(403);
    });

    it('should clear failed attempts for admin', async () => {
      const res = await request(app)
        .post('/api/v1/security/clear-failed-attempts')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ email: 'test@example.com' });

      expect(res.status).toBe(200);
      expect(res.body.data.email).toBe('test@example.com');
    });

    it('should reject invalid email', async () => {
      const res = await request(app)
        .post('/api/v1/security/clear-failed-attempts')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ email: 'invalid' });

      expect(res.status).toBe(400);
    });
  });

  describe('GET /api/v1/security/audit-logs', () => {
    it('should reject for non-admin users', async () => {
      const res = await request(app)
        .get('/api/v1/security/audit-logs')
        .set('Authorization', `Bearer ${userToken}`);

      expect(res.status).toBe(403);
    });

    it('should return audit logs for admin', async () => {
      const res = await request(app)
        .get('/api/v1/security/audit-logs')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data).toHaveProperty('logs');
      expect(res.body.data).toHaveProperty('total');
      expect(res.body.data).toHaveProperty('page');
      expect(res.body.data).toHaveProperty('limit');
      expect(res.body.data).toHaveProperty('totalPages');
    });
  });
});
