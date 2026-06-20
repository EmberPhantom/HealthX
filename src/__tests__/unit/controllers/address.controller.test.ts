import request from 'supertest';
import app from '../../../app';
import User from '../../../models/User';
import Address from '../../../models/Address';
import { authService } from '../../../services/auth.service';

describe('Address Controller Tests', () => {
  let user1Id: string;
  let user1Token: string;
  let user2Token: string;

  const validAddress = {
    label: 'Home',
    street: '123 Main St',
    area: 'Banjara Hills',
    city: 'Hyderabad',
    pincode: '500034',
  };

  beforeAll(async () => {
    await User.deleteMany({});
    await Address.deleteMany({});

    const user1 = await authService.signup('User One', 'user1@example.com', 'Password123!', '+1111111111');
    user1Id = user1.user.id;
    user1Token = user1.accessToken;

    const user2 = await authService.signup('User Two', 'user2@example.com', 'Password123!', '+2222222222');
    user2Token = user2.accessToken;
  });

  afterAll(async () => {
    await User.deleteMany({});
    await Address.deleteMany({});
  });

  describe('POST /api/v1/addresses', () => {
    it('should create an address successfully', async () => {
      const res = await request(app)
        .post('/api/v1/addresses')
        .set('Authorization', `Bearer ${user1Token}`)
        .send(validAddress);

      expect(res.status).toBe(201);
      expect(res.body.status).toBe('success');
      expect(res.body.data.label).toBe('Home');
      expect(res.body.data.city).toBe('Hyderabad');
      expect(res.body.data.isDefault).toBe(true); // first address becomes default
    });

    it('should reject address with invalid pincode', async () => {
      const res = await request(app)
        .post('/api/v1/addresses')
        .set('Authorization', `Bearer ${user1Token}`)
        .send({ ...validAddress, pincode: '123' });

      expect(res.status).toBe(400);
      expect(res.body.status).toBe('fail');
    });

    it('should reject address with missing required fields', async () => {
      const res = await request(app)
        .post('/api/v1/addresses')
        .set('Authorization', `Bearer ${user1Token}`)
        .send({ label: 'Incomplete' });

      expect(res.status).toBe(400);
    });

    it('should reject without auth token', async () => {
      const res = await request(app)
        .post('/api/v1/addresses')
        .send(validAddress);

      expect(res.status).toBe(401);
    });
  });

  describe('GET /api/v1/addresses', () => {
    it('should return user addresses', async () => {
      const res = await request(app)
        .get('/api/v1/addresses')
        .set('Authorization', `Bearer ${user1Token}`);

      expect(res.status).toBe(200);
      expect(res.body.status).toBe('success');
      expect(Array.isArray(res.body.data)).toBe(true);
      expect(res.body.data.length).toBeGreaterThanOrEqual(1);
    });

    it('should return empty array for user with no addresses', async () => {
      // Create and immediately delete any addresses for user2
      await Address.deleteMany({ userId: user1Id }); // remove user1 addresses too
      await Address.deleteMany({ userId: (await User.findOne({ email: 'user2@example.com' }))!._id });

      const res = await request(app)
        .get('/api/v1/addresses')
        .set('Authorization', `Bearer ${user2Token}`);

      expect(res.status).toBe(200);
      expect(res.body.data).toEqual([]);
    });
  });

  describe('PUT /api/v1/addresses/:id', () => {
    it('should update an address', async () => {
      // Create a fresh address for user1
      const addr = await Address.create({ ...validAddress, userId: user1Id, isDefault: true });
      await Address.deleteMany({ userId: (await User.findOne({ email: 'user2@example.com' }))!._id });

      const res = await request(app)
        .put(`/api/v1/addresses/${addr._id}`)
        .set('Authorization', `Bearer ${user1Token}`)
        .send({ label: 'Work', street: '456 Office Blvd' });

      expect(res.status).toBe(200);
      expect(res.body.data.label).toBe('Work');
      expect(res.body.data.street).toBe('456 Office Blvd');
    });

    it('should return 404 when updating another user\'s address', async () => {
      const addr = await Address.create({ ...validAddress, userId: user1Id });
      const res = await request(app)
        .put(`/api/v1/addresses/${addr._id}`)
        .set('Authorization', `Bearer ${user2Token}`)
        .send({ label: 'Hacked' });

      expect(res.status).toBe(404);
    });
  });

  describe('DELETE /api/v1/addresses/:id', () => {
    it('should delete own address', async () => {
      const addr = await Address.create({ ...validAddress, userId: user1Id });
      const res = await request(app)
        .delete(`/api/v1/addresses/${addr._id}`)
        .set('Authorization', `Bearer ${user1Token}`);

      expect(res.status).toBe(200);
      expect(res.body.data).toBeNull();

      const deleted = await Address.findById(addr._id);
      expect(deleted).toBeNull();
    });

    it('should return 404 when deleting another user\'s address', async () => {
      const addr = await Address.create({ ...validAddress, userId: user1Id });
      const res = await request(app)
        .delete(`/api/v1/addresses/${addr._id}`)
        .set('Authorization', `Bearer ${user2Token}`);

      expect(res.status).toBe(404);
    });
  });

  describe('PATCH /api/v1/addresses/:id/default', () => {
    it('should set address as default', async () => {
      const addr1 = await Address.create({ ...validAddress, label: 'Home', userId: user1Id });
      const addr2 = await Address.create({ ...validAddress, label: 'Work', street: '456 Work Rd', userId: user1Id });

      const res = await request(app)
        .patch(`/api/v1/addresses/${addr2._id}/default`)
        .set('Authorization', `Bearer ${user1Token}`);

      expect(res.status).toBe(200);
      expect(res.body.data.isDefault).toBe(true);

      const prevDefault = await Address.findById(addr1._id);
      expect(prevDefault!.isDefault).toBe(false);
    });
  });
});
