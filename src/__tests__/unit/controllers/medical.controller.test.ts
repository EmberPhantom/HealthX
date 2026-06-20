import request from 'supertest';
import app from '../../../app';
import User from '../../../models/User';
import VitalsLog from '../../../models/VitalsLog';
import GlucoseLog from '../../../models/GlucoseLog';
import InsulinLog from '../../../models/InsulinLog';
import MeasurementLog from '../../../models/MeasurementLog';
import { authService } from '../../../services/auth.service';

describe('Medical Controller Tests', () => {
  let userId: string;
  let accessToken: string;
  let otherToken: string;

  beforeAll(async () => {
    await User.deleteMany({});
    await VitalsLog.deleteMany({});
    await GlucoseLog.deleteMany({});
    await InsulinLog.deleteMany({});
    await MeasurementLog.deleteMany({});

    const user = await authService.signup('Medical Test User', 'medical.test@example.com', 'Password123!', '+19999999991');
    userId = user.user.id;
    accessToken = user.accessToken;

    const other = await authService.signup('Medical Other', 'medical.other@example.com', 'Password123!', '+19999999990');
    otherToken = other.accessToken;
  });

  afterAll(async () => {
    await User.deleteMany({});
    await VitalsLog.deleteMany({});
    await GlucoseLog.deleteMany({});
    await InsulinLog.deleteMany({});
    await MeasurementLog.deleteMany({});
  });

  // ─── Vitals ─────────────────────────────────────────────────────────────

  describe('POST /api/v1/trackers/vitals', () => {
    it('should log vitals successfully', async () => {
      const res = await request(app)
        .post('/api/v1/trackers/vitals')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          date: '2026-06-07',
          time: '08:00 AM',
          bp: '120/80',
          pulse: 72,
          temperature: 98.6,
          weight: 70,
          spo2: 98,
          exerciseMins: 30,
        });

      expect(res.status).toBe(201);
      expect(res.body.status).toBe('success');
      expect(res.body.data.pulse).toBe(72);
    });

    it('should reject invalid pulse range', async () => {
      const res = await request(app)
        .post('/api/v1/trackers/vitals')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          date: '2026-06-07',
          time: '08:00 AM',
          pulse: 500,
        });

      expect(res.status).toBe(400);
    });
  });

  describe('GET /api/v1/trackers/vitals', () => {
    beforeEach(async () => {
      await VitalsLog.deleteMany({});
    });

    it('should return vitals logs for the user', async () => {
      await VitalsLog.create({ userId, date: '2026-06-07', time: '08:00 AM', bp: '120/80', pulse: 72 });

      const res = await request(app)
        .get('/api/v1/trackers/vitals')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.length).toBeGreaterThanOrEqual(1);
    });

    it('should return empty array when no vitals logged', async () => {
      const res = await request(app)
        .get('/api/v1/trackers/vitals')
        .set('Authorization', `Bearer ${otherToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data).toEqual([]);
    });
  });

  describe('DELETE /api/v1/trackers/vitals/:id', () => {
    it('should delete own vitals log', async () => {
      const log = await VitalsLog.create({ userId, date: '2026-06-07', time: '08:00 AM', bp: '120/80', pulse: 72 });

      const res = await request(app)
        .delete(`/api/v1/trackers/vitals/${log._id}`)
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data).toBeNull();
    });

    it('should return 404 for other user vitals log', async () => {
      const log = await VitalsLog.create({ userId, date: '2026-06-07', time: '08:00 AM', bp: '120/80', pulse: 72 });

      const res = await request(app)
        .delete(`/api/v1/trackers/vitals/${log._id}`)
        .set('Authorization', `Bearer ${otherToken}`);

      expect(res.status).toBe(404);
    });
  });

  // ─── Glucose ─────────────────────────────────────────────────────────────

  describe('POST /api/v1/trackers/glucose', () => {
    it('should log glucose reading successfully', async () => {
      const res = await request(app)
        .post('/api/v1/trackers/glucose')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          level: 110,
          readingType: 'fasting',
          note: 'Pre-breakfast',
        });

      expect(res.status).toBe(201);
      expect(res.body.data.level).toBe(110);
      expect(res.body.data.readingType).toBe('fasting');
    });

    it('should reject out-of-range glucose level', async () => {
      const res = await request(app)
        .post('/api/v1/trackers/glucose')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          level: 700,
          readingType: 'random',
        });

      expect(res.status).toBe(400);
    });

    it('should reject invalid reading type', async () => {
      const res = await request(app)
        .post('/api/v1/trackers/glucose')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          level: 100,
          readingType: 'invalid_type',
        });

      expect(res.status).toBe(400);
    });
  });

  describe('GET /api/v1/trackers/glucose', () => {
    beforeEach(async () => {
      await GlucoseLog.deleteMany({});
    });

    it('should return glucose logs', async () => {
      await GlucoseLog.create({ userId, level: 110, readingType: 'fasting' });

      const res = await request(app)
        .get('/api/v1/trackers/glucose')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.length).toBeGreaterThanOrEqual(1);
    });
  });

  describe('DELETE /api/v1/trackers/glucose/:id', () => {
    it('should delete own glucose log', async () => {
      const log = await GlucoseLog.create({ userId, level: 110, readingType: 'fasting' });

      const res = await request(app)
        .delete(`/api/v1/trackers/glucose/${log._id}`)
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
    });

    it('should return 404 for other user glucose log', async () => {
      const log = await GlucoseLog.create({ userId, level: 110, readingType: 'fasting' });

      const res = await request(app)
        .delete(`/api/v1/trackers/glucose/${log._id}`)
        .set('Authorization', `Bearer ${otherToken}`);

      expect(res.status).toBe(404);
    });
  });

  // ─── Insulin ──────────────────────────────────────────────────────────────

  describe('POST /api/v1/trackers/insulin', () => {
    it('should log insulin successfully', async () => {
      const res = await request(app)
        .post('/api/v1/trackers/insulin')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          dose: 10,
          insulinType: 'Rapid-acting',
          injectionSite: 'Abdomen',
          mealContext: 'before_meal',
        });

      expect(res.status).toBe(201);
      expect(res.body.data.dose).toBe(10);
      expect(res.body.data.insulinType).toBe('Rapid-acting');
    });

    it('should reject negative dose', async () => {
      const res = await request(app)
        .post('/api/v1/trackers/insulin')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          dose: -5,
          insulinType: 'Rapid-acting',
        });

      expect(res.status).toBe(400);
    });
  });

  describe('GET /api/v1/trackers/insulin', () => {
    beforeEach(async () => {
      await InsulinLog.deleteMany({});
    });

    it('should return insulin logs', async () => {
      await InsulinLog.create({ userId, dose: 10, insulinType: 'Rapid-acting' });

      const res = await request(app)
        .get('/api/v1/trackers/insulin')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.length).toBeGreaterThanOrEqual(1);
    });
  });

  describe('DELETE /api/v1/trackers/insulin/:id', () => {
    it('should delete own insulin log', async () => {
      const log = await InsulinLog.create({ userId, dose: 10, insulinType: 'Rapid-acting' });

      const res = await request(app)
        .delete(`/api/v1/trackers/insulin/${log._id}`)
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
    });
  });

  // ─── Measurements ─────────────────────────────────────────────────────────

  describe('POST /api/v1/trackers/measurements', () => {
    it('should log measurements and calculate BMI', async () => {
      const res = await request(app)
        .post('/api/v1/trackers/measurements')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          weight: 70,
          height: 175,
          chest: 100,
          waist: 80,
          hips: 95,
          bodyFatPercent: 15,
        });

      expect(res.status).toBe(201);
      expect(res.body.data.bmi).toBeCloseTo(22.86, 1);
      expect(res.body.data.weight).toBe(70);
    });

    it('should reject invalid bodyFatPercent', async () => {
      const res = await request(app)
        .post('/api/v1/trackers/measurements')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          bodyFatPercent: 150,
        });

      expect(res.status).toBe(400);
    });
  });

  describe('GET /api/v1/trackers/measurements', () => {
    beforeEach(async () => {
      await MeasurementLog.deleteMany({});
    });

    it('should return measurement logs', async () => {
      await MeasurementLog.create({ userId, weight: 70, height: 175, bmi: 22.86 });

      const res = await request(app)
        .get('/api/v1/trackers/measurements')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.length).toBeGreaterThanOrEqual(1);
    });
  });

  describe('DELETE /api/v1/trackers/measurements/:id', () => {
    it('should delete own measurement log', async () => {
      const log = await MeasurementLog.create({ userId, weight: 70, height: 175 });

      const res = await request(app)
        .delete(`/api/v1/trackers/measurements/${log._id}`)
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
    });
  });
});
