import request from 'supertest';
import app from '../../app';
import User from '../../models/User';
import WaterLog from '../../models/WaterLog';
import SleepLog from '../../models/SleepLog';
import StepLog from '../../models/StepLog';
import { authService } from '../../services/auth.service';

describe('Tracker Controller Tests', () => {
  let userId: string;
  let accessToken: string;

  beforeAll(async () => {
    await User.deleteMany({});
    await WaterLog.deleteMany({});
    await SleepLog.deleteMany({});
    await StepLog.deleteMany({});

    const signupRes = await authService.signup(
      'Tracker Test User',
      'tracker.user@example.com',
      'Password123!',
      '+19999999999'
    );

    userId = signupRes.user.id;
    accessToken = signupRes.accessToken;
  });

  afterAll(async () => {
    await User.deleteMany({});
    await WaterLog.deleteMany({});
    await SleepLog.deleteMany({});
    await StepLog.deleteMany({});
  });

  describe('Water Tracking', () => {
    it('should log water intake successfully', async () => {
      const response = await request(app)
        .post('/api/v1/trackers/water')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ amount: 250 });

      expect(response.status).toBe(201);
      expect(response.body.status).toBe('success');
      expect(response.body.data.amount).toBe(250);
    });

    it('should retrieve water logs with date range filtering', async () => {
      const start = new Date(Date.now() - 1000 * 60 * 60);
      const end = new Date(Date.now() + 1000 * 60 * 60);

      const response = await request(app)
        .get('/api/v1/trackers/water')
        .set('Authorization', `Bearer ${accessToken}`)
        .query({ startDate: start.toISOString(), endDate: end.toISOString() });

      expect(response.status).toBe(200);
      expect(response.body.status).toBe('success');
      expect(Array.isArray(response.body.data)).toBe(true);
    });
  });

  describe('Sleep Tracking', () => {
    it('should log sleep session by upserting on userId + dateKey', async () => {
      const response1 = await request(app)
        .post('/api/v1/trackers/sleep')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ bedtime: '2026-06-07T22:00:00.000Z', wakeTime: '2026-06-08T06:00:00.000Z', dateKey: '2026-06-07' });

      expect(response1.status).toBe(200);
      expect(response1.body.data.bedtime).toBe('2026-06-07T22:00:00.000Z');

      // Update same sleep record (should upsert/overwrite)
      const response2 = await request(app)
        .post('/api/v1/trackers/sleep')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ bedtime: '2026-06-07T23:00:00.000Z', wakeTime: '2026-06-08T07:00:00.000Z', dateKey: '2026-06-07' });

      expect(response2.status).toBe(200);
      expect(response2.body.data.bedtime).toBe('2026-06-07T23:00:00.000Z');
      
      const count = await SleepLog.countDocuments({ userId, dateKey: '2026-06-07' });
      expect(count).toBe(1);
    });
  });

  describe('Step Tracking', () => {
    it('should log daily steps by upserting on userId + dateKey', async () => {
      const response = await request(app)
        .post('/api/v1/trackers/steps')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ steps: 8000, dateKey: '2026-06-07' });

      expect(response.status).toBe(200);
      expect(response.body.data.steps).toBe(8000);
    });
  });
});
