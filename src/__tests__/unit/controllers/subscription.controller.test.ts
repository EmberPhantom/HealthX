import request from 'supertest';
import app from '../../../app';
import User from '../../../models/User';
import UserSubscription from '../../../models/UserSubscription';
import MealPlan from '../../../models/MealPlan';
import Notification from '../../../models/Notification';
import { authService } from '../../../services/auth.service';

describe('Subscription Controller Tests', () => {
  let userId: string;
  let accessToken: string;
  let otherToken: string;
  let planId: string;

  beforeAll(async () => {
    await User.deleteMany({});
    await UserSubscription.deleteMany({});
    await MealPlan.deleteMany({});
    await Notification.deleteMany({});

    const user = await authService.signup('Sub Test User', 'sub.test@example.com', 'Password123!', '+19999999989');
    userId = user.user.id;
    accessToken = user.accessToken;

    const other = await authService.signup('Sub Other', 'sub.other@example.com', 'Password123!', '+19999999988');
    otherToken = other.accessToken;

    const plan = await MealPlan.create({
      planName: 'Test Plan',
      price: '₹999',
      subtitle: 'A test meal plan',
      accentColor: '#10B981',
      btnColor: '#059669',
      isFeatured: false,
      cardBgColor: '#ECFDF5',
      assetImagePath: 'assets/test.png',
      destination: '/meals/test',
    });
    planId = plan._id.toString();
  });

  afterAll(async () => {
    await User.deleteMany({});
    await UserSubscription.deleteMany({});
    await MealPlan.deleteMany({});
    await Notification.deleteMany({});
  });

  describe('POST /api/v1/subscriptions/subscribe', () => {
    beforeEach(async () => {
      await UserSubscription.deleteMany({});
      await Notification.deleteMany({});
    });

    it('should subscribe to a plan successfully', async () => {
      const res = await request(app)
        .post('/api/v1/subscriptions/subscribe')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ planId, billingPeriod: 'monthly' });

      expect(res.status).toBe(201);
      expect(res.body.status).toBe('success');
      expect(res.body.data.planName).toBe('Test Plan');
      expect(res.body.data.status).toBe('active');
    });

    it('should reject with non-existent planId', async () => {
      const res = await request(app)
        .post('/api/v1/subscriptions/subscribe')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ planId: '507f1f77bcf86cd799439999' });

      expect(res.status).toBe(404);
    });

    it('should cancel old subscription when subscribing to new plan', async () => {
      const plan2 = await MealPlan.create({
        planName: 'Second Plan',
        price: '₹1499',
        subtitle: 'Another plan',
        accentColor: '#3B82F6',
        btnColor: '#2563EB',
        isFeatured: false,
        cardBgColor: '#EFF6FF',
        assetImagePath: 'assets/test2.png',
        destination: '/meals/test2',
      });

      // Subscribe to first plan
      await request(app)
        .post('/api/v1/subscriptions/subscribe')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ planId });

      // Subscribe to second plan — should cancel first
      const res = await request(app)
        .post('/api/v1/subscriptions/subscribe')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ planId: plan2._id.toString() });

      expect(res.status).toBe(201);

      const oldSub = await UserSubscription.findOne({ userId, planId });
      expect(oldSub!.status).toBe('cancelled');
    });
  });

  describe('POST /api/v1/subscriptions/pause/:id', () => {
    beforeEach(async () => {
      await UserSubscription.deleteMany({});
      await Notification.deleteMany({});
    });

    it('should pause an active subscription', async () => {
      const sub = await UserSubscription.create({
        userId,
        planId,
        planName: 'Test Plan',
        price: '₹999',
        status: 'active',
        startDate: new Date(),
        endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        billingPeriod: 'monthly',
      });

      const res = await request(app)
        .post(`/api/v1/subscriptions/pause/${sub._id}`)
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.status).toBe('paused');
    });

    it('should return 404 when pausing another user subscription', async () => {
      const sub = await UserSubscription.create({
        userId,
        planId,
        planName: 'Test Plan',
        price: '₹999',
        status: 'active',
        startDate: new Date(),
        endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        billingPeriod: 'monthly',
      });

      const res = await request(app)
        .post(`/api/v1/subscriptions/pause/${sub._id}`)
        .set('Authorization', `Bearer ${otherToken}`);

      expect(res.status).toBe(404);
    });
  });

  describe('POST /api/v1/subscriptions/cancel/:id', () => {
    beforeEach(async () => {
      await UserSubscription.deleteMany({});
      await Notification.deleteMany({});
    });

    it('should cancel an active subscription', async () => {
      const sub = await UserSubscription.create({
        userId,
        planId,
        planName: 'Test Plan',
        price: '₹999',
        status: 'active',
        startDate: new Date(),
        endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        billingPeriod: 'monthly',
      });

      const res = await request(app)
        .post(`/api/v1/subscriptions/cancel/${sub._id}`)
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.status).toBe('cancelled');
    });

    it('should cancel a paused subscription', async () => {
      const sub = await UserSubscription.create({
        userId,
        planId,
        planName: 'Test Plan',
        price: '₹999',
        status: 'paused',
        startDate: new Date(),
        endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        billingPeriod: 'monthly',
      });

      const res = await request(app)
        .post(`/api/v1/subscriptions/cancel/${sub._id}`)
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
    });

    it('should return 404 for already cancelled subscription', async () => {
      const sub = await UserSubscription.create({
        userId,
        planId,
        planName: 'Test Plan',
        price: '₹999',
        status: 'cancelled',
        startDate: new Date(),
        endDate: new Date(),
        billingPeriod: 'monthly',
      });

      const res = await request(app)
        .post(`/api/v1/subscriptions/cancel/${sub._id}`)
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(404);
    });
  });

  describe('GET /api/v1/subscriptions/me', () => {
    beforeEach(async () => {
      await UserSubscription.deleteMany({});
    });

    it('should return user subscriptions', async () => {
      await UserSubscription.create({
        userId,
        planId,
        planName: 'Test Plan',
        price: '₹999',
        status: 'active',
        startDate: new Date(),
        endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        billingPeriod: 'monthly',
      });

      const res = await request(app)
        .get('/api/v1/subscriptions/me')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body.data)).toBe(true);
      expect(res.body.data.length).toBe(1);
    });

    it('should return empty array when no subscriptions exist', async () => {
      const res = await request(app)
        .get('/api/v1/subscriptions/me')
        .set('Authorization', `Bearer ${otherToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data).toEqual([]);
    });
  });
});
