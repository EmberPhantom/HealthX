import request from 'supertest';
import app from '../../../app';
import User from '../../../models/User';
import HealthRecord from '../../../models/HealthRecord';
import { authService } from '../../../services/auth.service';

// Mock the storage service to avoid actual file uploads
jest.mock('../../../services/storage.service', () => ({
  __esModule: true,
  default: {
    saveHealthRecordFile: jest.fn().mockResolvedValue('https://storage.test/records/file.pdf'),
    deleteFile: jest.fn().mockResolvedValue(undefined),
  },
}));

describe('HealthRecord Controller Tests', () => {
  let userId: string;
  let accessToken: string;
  let otherToken: string;

  beforeAll(async () => {
    await User.deleteMany({});
    await HealthRecord.deleteMany({});

    const user = await authService.signup('HR Test User', 'hr.test@example.com', 'Password123!', '+19999999997');
    userId = user.user.id;
    accessToken = user.accessToken;

    const other = await authService.signup('HR Other', 'hr.other@example.com', 'Password123!', '+19999999996');
    otherToken = other.accessToken;
  });

  afterAll(async () => {
    await User.deleteMany({});
    await HealthRecord.deleteMany({});
  });

  describe('POST /api/v1/health-records', () => {
    it('should reject without file upload', async () => {
      const res = await request(app)
        .post('/api/v1/health-records')
        .set('Authorization', `Bearer ${accessToken}`)
        .field('name', 'Blood Report')
        .field('type', 'labTests')
        .field('date', '2026-06-01');

      expect(res.status).toBe(400);
    });

    it('should reject with missing required fields', async () => {
      const res = await request(app)
        .post('/api/v1/health-records')
        .set('Authorization', `Bearer ${accessToken}`)
        .field('name', 'Blood Report');

      expect(res.status).toBe(400);
    });

    it('should reject invalid type', async () => {
      const res = await request(app)
        .post('/api/v1/health-records')
        .set('Authorization', `Bearer ${accessToken}`)
        .field('name', 'Blood Report')
        .field('type', 'invalid_type')
        .field('date', '2026-06-01');

      expect(res.status).toBe(400);
    });
  });

  describe('GET /api/v1/health-records', () => {
    beforeEach(async () => {
      await HealthRecord.deleteMany({});
    });

    it('should return empty array when no records exist', async () => {
      const res = await request(app)
        .get('/api/v1/health-records')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data).toEqual([]);
    });

    it('should return user health records', async () => {
      await HealthRecord.create({
        userId,
        name: 'X-Ray',
        type: 'scans',
        date: new Date('2026-06-01'),
        fileUrls: ['https://storage.test/xray.pdf'],
      });

      const res = await request(app)
        .get('/api/v1/health-records')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.length).toBe(1);
      expect(res.body.data[0].name).toBe('X-Ray');
    });

    it('should not return other user records', async () => {
      const res = await request(app)
        .get('/api/v1/health-records')
        .set('Authorization', `Bearer ${otherToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data).toEqual([]);
    });

    it('should filter by type', async () => {
      await HealthRecord.create({
        userId,
        name: 'Blood Report',
        type: 'labTests',
        date: new Date('2026-06-01'),
        fileUrls: ['https://storage.test/report.pdf'],
      });

      const res = await request(app)
        .get('/api/v1/health-records')
        .set('Authorization', `Bearer ${accessToken}`)
        .query({ type: 'labTests' });

      expect(res.status).toBe(200);
      expect(res.body.data.every((r: any) => r.type === 'labTests')).toBe(true);
    });
  });

  describe('DELETE /api/v1/health-records/:id', () => {
    it('should delete own health record', async () => {
      const record = await HealthRecord.create({
        userId,
        name: 'To Delete',
        type: 'other',
        date: new Date(),
        fileUrls: ['https://storage.test/delete.pdf'],
      });

      const res = await request(app)
        .delete(`/api/v1/health-records/${record._id}`)
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data).toBeNull();
    });

    it('should return 404 for other user record', async () => {
      const record = await HealthRecord.create({
        userId,
        name: 'Mine',
        type: 'other',
        date: new Date(),
        fileUrls: ['https://storage.test/mine.pdf'],
      });

      const res = await request(app)
        .delete(`/api/v1/health-records/${record._id}`)
        .set('Authorization', `Bearer ${otherToken}`);

      expect(res.status).toBe(404);
    });
  });
});
