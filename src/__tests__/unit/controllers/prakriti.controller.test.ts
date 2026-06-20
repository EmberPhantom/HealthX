import request from 'supertest';
import app from '../../../app';
import User from '../../../models/User';
import PrakritiAssessment from '../../../models/PrakritiAssessment';
import { authService } from '../../../services/auth.service';

describe('Prakriti Controller Tests', () => {
  let userId: string;
  let accessToken: string;
  let otherToken: string;

  beforeAll(async () => {
    await User.deleteMany({});
    await PrakritiAssessment.deleteMany({});

    const user = await authService.signup('Prakriti Test User', 'prakriti.test@example.com', 'Password123!', '+19999999995');
    userId = user.user.id;
    accessToken = user.accessToken;

    const other = await authService.signup('Prakriti Other', 'prakriti.other@example.com', 'Password123!', '+19999999994');
    otherToken = other.accessToken;
  });

  afterAll(async () => {
    await User.deleteMany({});
    await PrakritiAssessment.deleteMany({});
  });

  describe('GET /api/v1/prakriti/questions', () => {
    it('should return all quiz questions', async () => {
      const res = await request(app)
        .get('/api/v1/prakriti/questions')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
      expect(res.body.status).toBe('success');
      expect(Array.isArray(res.body.data)).toBe(true);
      expect(res.body.data.length).toBe(10);
      expect(res.body.data[0]).toHaveProperty('id');
      expect(res.body.data[0]).toHaveProperty('text');
      expect(res.body.data[0]).toHaveProperty('options');
      expect(res.body.data[0].options.length).toBe(3);
    });
  });

  describe('POST /api/v1/prakriti/submit', () => {
    beforeEach(async () => {
      await PrakritiAssessment.deleteMany({});
    });

    it('should submit assessment and return result', async () => {
      const answers = {
        frame: 'vata',
        skin: 'pitta',
        hair: 'kapha',
        digestion: 'vata',
        sleep: 'pitta',
        weather: 'kapha',
        mind: 'vata',
        speech: 'pitta',
        activity: 'kapha',
        stress: 'vata',
      };

      const res = await request(app)
        .post('/api/v1/prakriti/submit')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ answers });

      expect(res.status).toBe(200);
      expect(res.body.status).toBe('success');
      expect(res.body.data).toHaveProperty('assessment');
      expect(res.body.data).toHaveProperty('dominantDosha');
      expect(res.body.data).toHaveProperty('scores');
      expect(res.body.data).toHaveProperty('profile');
      expect(res.body.data.scores).toHaveProperty('vata');
      expect(res.body.data.scores).toHaveProperty('pitta');
      expect(res.body.data.scores).toHaveProperty('kapha');
    });

    it('should reject empty answers', async () => {
      const res = await request(app)
        .post('/api/v1/prakriti/submit')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ answers: {} });

      expect(res.status).toBe(400);
    });

    it('should reject missing answers', async () => {
      const res = await request(app)
        .post('/api/v1/prakriti/submit')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({});

      expect(res.status).toBe(400);
    });

    it('should save assessment to DB', async () => {
      const answers = { frame: 'vata', skin: 'pitta', hair: 'kapha' };

      await request(app)
        .post('/api/v1/prakriti/submit')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ answers });

      const saved = await PrakritiAssessment.findOne({ userId });
      expect(saved).not.toBeNull();
      expect(saved!.dominantDosha).toBeDefined();
    });
  });
});
