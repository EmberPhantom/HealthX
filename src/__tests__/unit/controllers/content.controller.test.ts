import request from 'supertest';
import app from '../../../app';
import User from '../../../models/User';
import Category from '../../../models/Category';
import Banner from '../../../models/Banner';
import MealPlan from '../../../models/MealPlan';
import MenuItem from '../../../models/MenuItem';
import { authService } from '../../../services/auth.service';

describe('Content Controller Tests', () => {
  let accessToken: string;

  beforeAll(async () => {
    await User.deleteMany({});
    await Category.deleteMany({});
    await Banner.deleteMany({});
    await MealPlan.deleteMany({});
    await MenuItem.deleteMany({});

    const user = await authService.signup('Content Test User', 'content.test@example.com', 'Password123!', '+19999999998');
    accessToken = user.accessToken;

    await Category.create({ name: 'Breakfast', emoji: '🍳' });
    await Category.create({ name: 'Lunch', emoji: '🍲' });

    await Banner.create({ title: 'Sale', imagePath: 'sale.jpg', subtitle: 'Big discounts', chipLabel: 'Sale' });

    await MealPlan.create({
      planName: 'Starter Plan',
      price: '₹999',
      subtitle: 'Basic meals',
      accentColor: '#10B981',
      btnColor: '#059669',
      isFeatured: false,
      cardBgColor: '#ECFDF5',
      assetImagePath: 'assets/starter.png',
      destination: '/meals/starter',
    });

    await MenuItem.create({
      name: 'Idli',
      price: 30,
      category: 'Breakfast',
      description: 'Soft rice cakes',
      calories: 120,
      imageUrl: 'idli.jpg',
    });
  });

  afterAll(async () => {
    await User.deleteMany({});
    await Category.deleteMany({});
    await Banner.deleteMany({});
    await MealPlan.deleteMany({});
    await MenuItem.deleteMany({});
  });

  describe('GET /api/v1/content/categories', () => {
    it('should return all categories', async () => {
      const res = await request(app)
        .get('/api/v1/content/categories')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
      expect(res.body.status).toBe('success');
      expect(Array.isArray(res.body.data)).toBe(true);
      expect(res.body.data.length).toBeGreaterThanOrEqual(2);
    });
  });

  describe('GET /api/v1/content/banners', () => {
    it('should return all banners', async () => {
      const res = await request(app)
        .get('/api/v1/content/banners')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.length).toBeGreaterThanOrEqual(1);
      expect(res.body.data[0].title).toBe('Sale');
    });
  });

  describe('GET /api/v1/content/meal-plans', () => {
    it('should return all meal plans', async () => {
      const res = await request(app)
        .get('/api/v1/content/meal-plans')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.length).toBeGreaterThanOrEqual(1);
      expect(res.body.data[0].planName).toBe('Starter Plan');
    });
  });

  describe('GET /api/v1/content/menu-items', () => {
    it('should return all menu items', async () => {
      const res = await request(app)
        .get('/api/v1/content/menu-items')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.length).toBeGreaterThanOrEqual(1);
    });

    it('should filter menu items by type', async () => {
      const res = await request(app)
        .get('/api/v1/content/menu-items')
        .set('Authorization', `Bearer ${accessToken}`)
        .query({ type: 'Breakfast' });

      expect(res.status).toBe(200);
      expect(res.body.data.every((i: any) => i.category === 'Breakfast')).toBe(true);
    });
  });

  describe('GET /api/v1/content/subscription-plans', () => {
    it('should return all membership plans', async () => {
      const res = await request(app)
        .get('/api/v1/content/subscription-plans')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
      expect(res.body.status).toBe('success');
      expect(Array.isArray(res.body.data)).toBe(true);
      expect(res.body.data.some((p: any) => p.planId === 'pro')).toBe(true);
    });
  });

  describe('GET /api/v1/content/reward-tasks', () => {
    it('should return rewards config tasks', async () => {
      const res = await request(app)
        .get('/api/v1/content/reward-tasks')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
      expect(res.body.status).toBe('success');
      expect(Array.isArray(res.body.data)).toBe(true);
      expect(res.body.data.some((t: any) => t.taskId === 'steps')).toBe(true);
    });
  });

  describe('GET /api/v1/content/support-info', () => {
    it('should return help support details and FAQs', async () => {
      const res = await request(app)
        .get('/api/v1/content/support-info')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
      expect(res.body.status).toBe('success');
      expect(res.body.data.email).toBe('support@healthxworld.com');
      expect(Array.isArray(res.body.data.faqs)).toBe(true);
    });
  });
});
