import mongoose from 'mongoose';
import { mealService } from '../../services/meal.service';
import MealLog from '../../models/MealLog';
import User from '../../models/User';

describe('Meal Service Unit Tests', () => {
  let userId: string;

  beforeAll(async () => {
    const user = await User.create({
      name: 'Meal Test User',
      email: 'mealtest@example.com',
      password: 'password123',
      phone: '+919999999999',
    });
    userId = user._id.toString();
  });

  afterAll(async () => {
    await User.deleteMany({});
    await MealLog.deleteMany({});
  });

  describe('identifyMeal', () => {
    test('UNIT-MealService-001: Should identify meal and return nutrition data', async () => {
      const result = await mealService.identifyMeal({ text: 'Mixed snack' });

      expect(result).toBeDefined();
      expect(result.name).toBe('Mixed snack platter');
      expect(result.calories).toBeGreaterThan(0);
      expect(result.ingredients.length).toBeGreaterThan(0);
    });
  });

  describe('logMeal', () => {
    test('UNIT-MealService-002: Should log a meal successfully', async () => {
      const mealData = {
        mealType: 'Lunch',
        foodName: 'Grilled Chicken',
        calories: 500,
        protein: 40,
        fat: 10,
        carbs: 5,
        ingredients: ['Chicken', 'Spices'],
      };

      const mealLog = await mealService.logMeal(userId, mealData);

      expect(mealLog).toBeDefined();
      expect(mealLog.foodName).toBe('Grilled Chicken');
      expect(mealLog.userId.toString()).toBe(userId);
    });
  });

  describe('getMealsByDate', () => {
    test('UNIT-MealService-003: Should fetch meals for a specific date', async () => {
      const date = new Date();
      const meals = await mealService.getMealsByDate(userId, date);

      expect(Array.isArray(meals)).toBe(true);
      expect(meals.length).toBeGreaterThan(0);
    });
  });
});
