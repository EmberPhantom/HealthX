import request from 'supertest';
import app from '../../../app';
import User from '../../../models/User';
import Order from '../../../models/Order';
import Notification from '../../../models/Notification';
import { authService } from '../../../services/auth.service';

describe('Order Controller Tests', () => {
  let userId: string;
  let accessToken: string;
  let otherToken: string;

  const sampleItems = [
    { menuItemId: '507f1f77bcf86cd799439013', name: 'Item 1', quantity: 2, price: 100 },
  ];

  beforeAll(async () => {
    await User.deleteMany({});
    await Order.deleteMany({});
    await Notification.deleteMany({});

    const user = await authService.signup('Order Test User', 'order.test@example.com', 'Password123!', '+19999999987');
    userId = user.user.id;
    accessToken = user.accessToken;

    const other = await authService.signup('Order Other', 'order.other@example.com', 'Password123!', '+19999999986');
    otherToken = other.accessToken;
  });

  afterAll(async () => {
    await User.deleteMany({});
    await Order.deleteMany({});
    await Notification.deleteMany({});
  });

  describe('POST /api/v1/orders', () => {
    beforeEach(async () => {
      await Order.deleteMany({});
      await Notification.deleteMany({});
    });

    it('should place an order successfully', async () => {
      const res = await request(app)
        .post('/api/v1/orders')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          items: sampleItems,
          addressId: '507f1f77bcf86cd799439020',
          paymentMethod: 'COD',
        });

      expect(res.status).toBe(201);
      expect(res.body.status).toBe('success');
      expect(res.body.data.items).toHaveLength(1);
      expect(res.body.data.total).toBeGreaterThan(0);
      expect(res.body.data.status).toBe('placed');
    });

    it('should calculate totals correctly', async () => {
      const items = [
        { menuItemId: '507f1f77bcf86cd799439013', name: 'Item 1', quantity: 2, price: 100 },
        { menuItemId: '507f1f77bcf86cd799439014', name: 'Item 2', quantity: 1, price: 50 },
      ];
      const subtotal = 2 * 100 + 1 * 50; // 250
      const deliveryFee = 40;
      const tax = Math.round(subtotal * 0.05 * 100) / 100; // 12.5

      const res = await request(app)
        .post('/api/v1/orders')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          items,
          addressId: '507f1f77bcf86cd799439020',
          paymentMethod: 'Card',
        });

      expect(res.status).toBe(201);
      expect(res.body.data.subtotal).toBe(subtotal);
      expect(res.body.data.deliveryFee).toBe(deliveryFee);
      expect(res.body.data.tax).toBe(tax);
      expect(res.body.data.total).toBe(subtotal + deliveryFee + tax);
    });

    it('should reject empty order', async () => {
      const res = await request(app)
        .post('/api/v1/orders')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          items: [],
          addressId: '507f1f77bcf86cd799439020',
          paymentMethod: 'COD',
        });

      expect(res.status).toBe(400);
    });

    it('should reject without auth', async () => {
      const res = await request(app)
        .post('/api/v1/orders')
        .send({
          items: sampleItems,
          addressId: '507f1f77bcf86cd799439020',
          paymentMethod: 'COD',
        });

      expect(res.status).toBe(401);
    });

    it('should mark online payments as paid', async () => {
      const res = await request(app)
        .post('/api/v1/orders')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          items: sampleItems,
          addressId: '507f1f77bcf86cd799439020',
          paymentMethod: 'Card',
        });

      expect(res.body.data.isPaid).toBe(true);
    });

    it('should mark COD as unpaid', async () => {
      const res = await request(app)
        .post('/api/v1/orders')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          items: sampleItems,
          addressId: '507f1f77bcf86cd799439020',
          paymentMethod: 'COD',
        });

      expect(res.body.data.isPaid).toBe(false);
    });
  });

  describe('GET /api/v1/orders', () => {
    beforeEach(async () => {
      await Order.deleteMany({});
    });

    it('should return orders for the user', async () => {
      await Order.create({
        userId,
        items: sampleItems,
        subtotal: 200,
        deliveryFee: 40,
        tax: 10,
        total: 250,
        status: 'placed',
        paymentMethod: 'COD',
        isPaid: false,
        deliveryPartner: { name: 'Test', phone: '+91', vehicleNo: 'KA-01' },
        estimatedDelivery: new Date(),
      });

      const res = await request(app)
        .get('/api/v1/orders')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.length).toBe(1);
    });

    it('should return empty array for user with no orders', async () => {
      const res = await request(app)
        .get('/api/v1/orders')
        .set('Authorization', `Bearer ${otherToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data).toEqual([]);
    });
  });

  describe('GET /api/v1/orders/:id', () => {
    beforeEach(async () => {
      await Order.deleteMany({});
    });

    it('should get order by id', async () => {
      const order = await Order.create({
        userId,
        items: sampleItems,
        subtotal: 200,
        deliveryFee: 40,
        tax: 10,
        total: 250,
        status: 'placed',
        paymentMethod: 'COD',
        isPaid: false,
        deliveryPartner: { name: 'Test', phone: '+91', vehicleNo: 'KA-01' },
        estimatedDelivery: new Date(),
      });

      const res = await request(app)
        .get(`/api/v1/orders/${order._id}`)
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data._id).toBe(order._id.toString());
    });

    it('should return 404 for other user order', async () => {
      const order = await Order.create({
        userId,
        items: sampleItems,
        subtotal: 200,
        deliveryFee: 40,
        tax: 10,
        total: 250,
        status: 'placed',
        paymentMethod: 'COD',
        isPaid: false,
        deliveryPartner: { name: 'Test', phone: '+91', vehicleNo: 'KA-01' },
        estimatedDelivery: new Date(),
      });

      const res = await request(app)
        .get(`/api/v1/orders/${order._id}`)
        .set('Authorization', `Bearer ${otherToken}`);

      expect(res.status).toBe(404);
    });
  });

  describe('POST /api/v1/orders/:id/cancel', () => {
    beforeEach(async () => {
      await Order.deleteMany({});
      await Notification.deleteMany({});
    });

    it('should cancel a placed order', async () => {
      const order = await Order.create({
        userId,
        items: sampleItems,
        subtotal: 200,
        deliveryFee: 40,
        tax: 10,
        total: 250,
        status: 'placed',
        paymentMethod: 'COD',
        isPaid: false,
        deliveryPartner: { name: 'Test', phone: '+91', vehicleNo: 'KA-01' },
        estimatedDelivery: new Date(),
      });

      const res = await request(app)
        .post(`/api/v1/orders/${order._id}/cancel`)
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ cancelReason: 'Changed my mind' });

      expect(res.status).toBe(200);
      expect(res.body.data.status).toBe('cancelled');
    });

    it('should return 400 for delivered order', async () => {
      const order = await Order.create({
        userId,
        items: sampleItems,
        subtotal: 200,
        deliveryFee: 40,
        tax: 10,
        total: 250,
        status: 'delivered',
        paymentMethod: 'COD',
        isPaid: false,
        deliveryPartner: { name: 'Test', phone: '+91', vehicleNo: 'KA-01' },
        estimatedDelivery: new Date(),
      });

      const res = await request(app)
        .post(`/api/v1/orders/${order._id}/cancel`)
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(400);
    });
  });

  describe('GET /api/v1/orders/:id/status', () => {
    beforeEach(async () => {
      await Order.deleteMany({});
    });

    it('should get order status', async () => {
      const order = await Order.create({
        userId,
        items: sampleItems,
        subtotal: 200,
        deliveryFee: 40,
        tax: 10,
        total: 250,
        status: 'placed',
        paymentMethod: 'COD',
        isPaid: false,
        deliveryPartner: { name: 'Test', phone: '+91', vehicleNo: 'KA-01' },
        estimatedDelivery: new Date(),
      });

      const res = await request(app)
        .get(`/api/v1/orders/${order._id}/status`)
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data).toHaveProperty('status');
      expect(res.body.data).toHaveProperty('estimatedDelivery');
    });

    it('should return 404 for non-existent order', async () => {
      const res = await request(app)
        .get('/api/v1/orders/507f1f77bcf86cd799439999/status')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(404);
    });
  });
});
