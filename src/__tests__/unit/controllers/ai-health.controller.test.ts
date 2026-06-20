import request from 'supertest';
import app from '../../../app';
import User from '../../../models/User';
import Patient from '../../../models/Patient';
import AIHealthProfile from '../../../models/AIHealthProfile';
import { authService } from '../../../services/auth.service';
import aiHealthService from '../../../services/ai-health.service';

// Mock aiHealthService
jest.mock('../../../services/ai-health.service');

// Mock worker scripts to avoid Redis queue connectivity issues in tests
jest.mock('../../../scripts/ai-health.worker', () => ({
  getAIAnalysisQueue: () => ({
    add: jest.fn().mockResolvedValue({ id: 'mock-analysis-job-id' }),
  }),
  getAIReanalysisQueue: () => ({
    add: jest.fn().mockResolvedValue({ id: 'mock-reanalysis-job-id' }),
  }),
}));

describe('AIHealthController Tests', () => {
  let userId: string;
  let accessToken: string;

  beforeAll(async () => {
    // Clear collections
    await User.deleteMany({});
    await Patient.deleteMany({});
    await AIHealthProfile.deleteMany({});

    // Create a real user using authService to get valid JWT token
    const userResult = await authService.signup(
      'AI Test User',
      'ai.test@example.com',
      'Password123!',
      '+19999999993'
    );
    userId = userResult.user.id;
    accessToken = userResult.accessToken;
  });

  afterAll(async () => {
    await User.deleteMany({});
    await Patient.deleteMany({});
    await AIHealthProfile.deleteMany({});
  });

  beforeEach(async () => {
    jest.clearAllMocks();
    await AIHealthProfile.deleteMany({});
  });

  describe('GET /api/v1/ai-health/step5-questions', () => {
    it('should return 401 if unauthorized', async () => {
      const res = await request(app).get('/api/v1/ai-health/step5-questions');
      expect(res.status).toBe(401);
    });

    it('should return AI-generated questions for authenticated user', async () => {
      const mockQuestions = [
        { id: 'q1', text: 'Sample question?', type: 'boolean' }
      ];
      (aiHealthService.generateStep5Questions as jest.Mock).mockResolvedValue(mockQuestions);

      const res = await request(app)
        .get('/api/v1/ai-health/step5-questions')
        .set('Authorization', `Bearer ${accessToken}`)
        .set('Accept-Language', 'en-US,en;q=0.9');

      expect(res.status).toBe(200);
      expect(res.body.status).toBe('success');
      expect(res.body.data.questions).toEqual(mockQuestions);
      expect(res.body.data.locale).toBe('en');
      expect(aiHealthService.generateStep5Questions).toHaveBeenCalledWith(userId, 'en');
    });
  });

  describe('POST /api/v1/ai-health/analyze', () => {
    it('should return 401 if unauthorized', async () => {
      const res = await request(app).post('/api/v1/ai-health/analyze').send({});
      expect(res.status).toBe(401);
    });

    it('should queue the analysis and return 202', async () => {
      const res = await request(app)
        .post('/api/v1/ai-health/analyze')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          responses: [
            { questionId: 'q1', questionText: 'Sample?', answer: true }
          ]
        });

      expect(res.status).toBe(202);
      expect(res.body.status).toBe('success');
      expect(res.body.data.jobId).toBe('mock-analysis-job-id');
      expect(res.body.data.analysisStatus).toBe('pending');

      // Check that AIHealthProfile document is created in DB with status pending
      const profile = await AIHealthProfile.findOne({ userId });
      expect(profile).toBeDefined();
      expect(profile?.status).toBe('pending');
      expect(profile?.step5Responses[0].questionId).toBe('q1');
    });

    it('should return 400 if responses array is missing or invalid', async () => {
      const res = await request(app)
        .post('/api/v1/ai-health/analyze')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          responses: 'not-an-array'
        });

      expect(res.status).toBe(400);
    });
  });

  describe('GET /api/v1/ai-health/profile', () => {
    it('should return 401 if unauthorized', async () => {
      const res = await request(app).get('/api/v1/ai-health/profile');
      expect(res.status).toBe(401);
    });

    it('should return 200 with null and message if no profile exists', async () => {
      (aiHealthService.getProfile as jest.Mock).mockResolvedValue(null);

      const res = await request(app)
        .get('/api/v1/ai-health/profile')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
      expect(res.body.status).toBe('success');
      expect(res.body.data).toBeNull();
      expect(res.body.message).toContain('No AI health profile found');
    });

    it('should return the health profile if it exists', async () => {
      const mockProfile = { userId, status: 'complete', conditions: [] };
      (aiHealthService.getProfile as jest.Mock).mockResolvedValue(mockProfile);

      const res = await request(app)
        .get('/api/v1/ai-health/profile')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
      expect(res.body.status).toBe('success');
      expect(res.body.data).toEqual(mockProfile);
    });
  });

  describe('GET /api/v1/ai-health/profile/status', () => {
    it('should return not_started status if profile does not exist', async () => {
      await AIHealthProfile.deleteOne({ userId });

      const res = await request(app)
        .get('/api/v1/ai-health/profile/status')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
      expect(res.body.status).toBe('success');
      expect(res.body.data.status).toBe('not_started');
    });

    it('should return current status if profile exists', async () => {
      await AIHealthProfile.create({
        userId,
        status: 'complete',
        analysisVersion: 2,
      });

      const res = await request(app)
        .get('/api/v1/ai-health/profile/status')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
      expect(res.body.status).toBe('success');
      expect(res.body.data.status).toBe('complete');
      expect(res.body.data.version).toBe(2);
    });
  });

  describe('GET /api/v1/ai-health/meal-warning', () => {
    it('should return 400 if foodName query parameter is missing', async () => {
      const res = await request(app)
        .get('/api/v1/ai-health/meal-warning')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(400);
    });

    it('should return meal warning from service', async () => {
      await AIHealthProfile.create({
        userId,
        status: 'complete',
        inlineSuggestionConfig: {
          mealTriggerKeywords: ['sugar']
        }
      });

      (aiHealthService.getMealInlineWarning as jest.Mock).mockReturnValue('Warning: contains sugar');

      const res = await request(app)
        .get('/api/v1/ai-health/meal-warning')
        .set('Authorization', `Bearer ${accessToken}`)
        .query({
          foodName: 'Cake',
          ingredients: 'sugar,flour',
          carbs: 50,
          calories: 300
        });

      expect(res.status).toBe(200);
      expect(res.body.status).toBe('success');
      expect(res.body.data.warning).toBe('Warning: contains sugar');
      expect(aiHealthService.getMealInlineWarning).toHaveBeenCalledWith(
        expect.any(Object),
        {
          foodName: 'Cake',
          ingredients: ['sugar', 'flour'],
          carbs: 50,
          calories: 300
        }
      );
    });
  });
});
