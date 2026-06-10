import request from 'supertest';
import app from '../../app';
import User from '../../models/User';
import Notification from '../../models/Notification';
import { authService } from '../../services/auth.service';

describe('Notification Controller Tests', () => {
  let userAId: string;
  let userAToken: string;
  let userBToken: string;

  beforeAll(async () => {
    await User.deleteMany({});
    await Notification.deleteMany({});

    // Create User A
    const signupResA = await authService.signup(
      'User A',
      'usera@example.com',
      'password123',
      '+917777777777'
    );
    userAId = signupResA.user.id;
    userAToken = signupResA.accessToken;

    // Create User B
    const signupResB = await authService.signup(
      'User B',
      'userb@example.com',
      'password123',
      '+917777777778'
    );
    userBToken = signupResB.accessToken;

    // Create a notification for User A
    await Notification.create({
      userId: userAId,
      title: 'User A Notification',
      body: 'Hello User A',
      type: 'info',
    });
  });

  afterAll(async () => {
    await User.deleteMany({});
    await Notification.deleteMany({});
  });

  describe('GET /api/v1/notifications', () => {
    test('Should get user A notifications', async () => {
      const response = await request(app)
        .get('/api/v1/notifications')
        .set('Authorization', `Bearer ${userAToken}`);

      expect(response.status).toBe(200);
      expect(response.body.status).toBe('success');
      expect(Array.isArray(response.body.data)).toBe(true);
      expect(response.body.data.length).toBe(1);
      expect(response.body.data[0].title).toBe('User A Notification');
    });
  });

  describe('PATCH /api/v1/notifications/:id/read', () => {
    test('Should reject marking another user\'s notification as read', async () => {
      const notif = await Notification.findOne({ userId: userAId });

      // Try to mark as read using User B's token
      const response = await request(app)
        .patch(`/api/v1/notifications/${notif!._id}/read`)
        .set('Authorization', `Bearer ${userBToken}`);

      expect(response.status).toBe(404);
      expect(response.body.message).toBe('Notification not found');
    });

    test('Should mark notification as read for the owner', async () => {
      const notif = await Notification.findOne({ userId: userAId });

      const response = await request(app)
        .patch(`/api/v1/notifications/${notif!._id}/read`)
        .set('Authorization', `Bearer ${userAToken}`);

      expect(response.status).toBe(200);
      expect(response.body.data.isRead).toBe(true);
    });
  });

  describe('DELETE /api/v1/notifications/:id', () => {
    test('Should reject deleting another user\'s notification', async () => {
      const notif = await Notification.findOne({ userId: userAId });

      const response = await request(app)
        .delete(`/api/v1/notifications/${notif!._id}`)
        .set('Authorization', `Bearer ${userBToken}`);

      expect(response.status).toBe(404);
    });

    test('Should delete notification successfully for the owner', async () => {
      const notif = await Notification.findOne({ userId: userAId });

      const response = await request(app)
        .delete(`/api/v1/notifications/${notif!._id}`)
        .set('Authorization', `Bearer ${userAToken}`);

      expect(response.status).toBe(204);

      const check = await Notification.findById(notif!._id);
      expect(check).toBeNull();
    });
  });
});
