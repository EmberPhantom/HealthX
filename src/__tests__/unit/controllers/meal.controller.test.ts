import request from 'supertest';
import app from '../../../app';
import User from '../../../models/User';
import MealLog from '../../../models/MealLog';
import { authService } from '../../../services/auth.service';

// Mock meal service to avoid external API calls
jest.mock('../../../services/meal.service', () => ({
  mealService: {
    identifyMeal: jest.fn().mockImplementation(({ text, imageUrl }) => {
      if (text === 'unknown') throw new Error('Identification failed');
      return Promise.resolve({
        name: 'Mixed snack platter',
        calories: 350,
        protein: 12,
        fat: 15,
        carbs: 45,
        ingredients: ['Nuts', 'Seeds', 'Dried fruits'],
        mealType: 'Snack',
      });
    }),
    logMeal: jest.fn().mockImplementation((userId, data) => {
      return Promise.resolve({
        _id: '507f1f77bcf86cd799439100',
        userId,
        ...data,
        loggedAt: new Date(),
      });
    }),
    getMealsByDate: jest.fn().mockImplementation((userId, date) => {
      return Promise.resolve([]);
    }),
    deleteMealLog: jest.fn().mockImplementation((userId, mealId) => {
      if (mealId === '507f1f77bcf86cd799439999') return Promise.resolve(null);
      return Promise.resolve({ _id: mealId, userId });
    }),
  },
}));

describe('Meal Controller Tests', () => {
  let userId: string;
  let accessToken: string;

  beforeAll(async () => {
    await User.deleteMany({});
    await MealLog.deleteMany({});

    const user = await authService.signup('Meal Test User', 'meal.test@example.com', 'Password123!', '+19999999993');
    userId = user.user.id;
    accessToken = user.accessToken;
  });

  afterAll(async () => {
    await User.deleteMany({});
    await MealLog.deleteMany({});
  });

  describe('POST /api/v1/meals/identify', () => {
    it('should identify meal from text', async () => {
      const res = await request(app)
        .post('/api/v1/meals/identify')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ text: 'Mixed snack' });

      expect(res.status).toBe(200);
      expect(res.body.status).toBe('success');
      expect(res.body.data.name).toBe('Mixed snack platter');
      expect(res.body.data.calories).toBeGreaterThan(0);
    });

    it('should reject when both text and imageUrl are missing', async () => {
      const res = await request(app)
        .post('/api/v1/meals/identify')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({});

      expect(res.status).toBe(400);
    });
  });

  describe('POST /api/v1/meals/log', () => {
    it('should log a meal successfully', async () => {
      const res = await request(app)
        .post('/api/v1/meals/log')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          mealType: 'Lunch',
          foodName: 'Grilled Chicken',
          calories: 500,
          protein: 40,
          fat: 10,
          carbs: 5,
          ingredients: ['Chicken', 'Spices'],
        });

      expect(res.status).toBe(201);
      expect(res.body.status).toBe('success');
    });

    it('should reject invalid mealType', async () => {
      const res = await request(app)
        .post('/api/v1/meals/log')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          mealType: 'Invalid',
          foodName: 'Something',
          calories: 100,
        });

      expect(res.status).toBe(400);
    });
  });

  describe('GET /api/v1/meals', () => {
    it('should return meal logs for the user', async () => {
      const res = await request(app)
        .get('/api/v1/meals')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
      expect(res.body.status).toBe('success');
      expect(Array.isArray(res.body.data)).toBe(true);
    });
  });

  describe('DELETE /api/v1/meals/:id', () => {
    it('should return 404 for non-existent meal log', async () => {
      const res = await request(app)
        .delete('/api/v1/meals/507f1f77bcf86cd799439999')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(404);
    });
  });
});
