import * as userController from '../../../controllers/user.controller';
import User from '../../../models/User';
import Order from '../../../models/Order';
import { Request, Response } from 'express';
import { AuthRequest } from '../../../middlewares/auth.middleware';

describe('User Controller Tests', () => {
  let mockReq: Partial<AuthRequest>;
  let mockRes: Partial<Response>;
  let jsonMock: jest.Mock;
  let statusMock: jest.Mock;

  const mockItemId1 = '507f1f77bcf86cd799439013';
  const mockItemId2 = '507f1f77bcf86cd799439014';
  const mockItemId3 = '507f1f77bcf86cd799439015';

  const runMiddleware = (middleware: any, req: any, res: any) => {
    return new Promise<void>((resolve, reject) => {
      const next = (err?: any) => {
        if (err) reject(err);
        else resolve();
      };
      
      const originalStatus = res.status;
      res.status = function(code: number) {
        const result = originalStatus.call(this, code);
        resolve();
        return result;
      };
      
      middleware(req, res, next);
    });
  };

  beforeEach(async () => {
    await User.deleteMany({});
    await Order.deleteMany({});
    jsonMock = jest.fn();
    statusMock = jest.fn().mockReturnValue({ json: jsonMock });
    mockReq = {
      user: {
        userId: '507f1f77bcf86cd799439012',
        role: 'user',
      },
      body: {},
    };
    mockRes = {
      status: statusMock,
    };
  });

  afterAll(async () => {
    await User.deleteMany({});
    await Order.deleteMany({});
  });

  describe('getStats', () => {
    it('should aggregate stats correctly for a user', async () => {
      const user = await User.create({
        _id: '507f1f77bcf86cd799439012',
        name: 'Stats User',
        email: 'stats@example.com',
        password: 'Password123!',
        phone: '+1234567890',
        favorites: [mockItemId1 as any, mockItemId2 as any],
        appRating: 4,
        points: 100,
      });

      await Order.create({
        userId: user._id,
        items: [{ menuItemId: mockItemId1 as any, quantity: 1, name: 'Item 1', price: 10 }],
        subtotal: 10,
        deliveryFee: 2,
        tax: 1,
        total: 13,
        status: 'delivered',
        paymentMethod: 'card',
        isPaid: true,
      });

      await runMiddleware(userController.getStats, mockReq, mockRes);

      expect(statusMock).toHaveBeenCalledWith(200);
      expect(jsonMock).toHaveBeenCalledWith(
        expect.objectContaining({
          status: 'success',
          data: expect.objectContaining({
            totalOrders: 1,
            favoritesCount: 2,
            rating: 4,
            points: 100,
          }),
        })
      );
    });
  });

  describe('toggleFavorite', () => {
    it('should add item to favorites if not already present', async () => {
      const user = await User.create({
        _id: '507f1f77bcf86cd799439012',
        name: 'Favorite User',
        email: 'fav@example.com',
        password: 'Password123!',
        phone: '+1234567890',
        favorites: [],
      });

      mockReq.body = { itemId: mockItemId3 };

      await runMiddleware(userController.toggleFavorite, mockReq, mockRes);

      const updatedUser = await User.findById(user._id);
      expect(updatedUser!.favorites.map(id => id.toString())).toContain(mockItemId3);
      expect(statusMock).toHaveBeenCalledWith(200);
      expect(jsonMock).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            isFavorite: true,
          }),
        })
      );
    });

    it('should remove item from favorites if already present', async () => {
      const user = await User.create({
        _id: '507f1f77bcf86cd799439012',
        name: 'Favorite User',
        email: 'fav@example.com',
        password: 'Password123!',
        phone: '+1234567890',
        favorites: [mockItemId3 as any],
      });

      mockReq.body = { itemId: mockItemId3 };

      await runMiddleware(userController.toggleFavorite, mockReq, mockRes);

      const updatedUser = await User.findById(user._id);
      expect(updatedUser!.favorites.map(id => id.toString())).not.toContain(mockItemId3);
      expect(jsonMock).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            isFavorite: false,
          }),
        })
      );
    });
  });

  describe('deleteAccount', () => {
    it('should delete user and associated records and return 200', async () => {
      const user = await User.create({
        _id: '507f1f77bcf86cd799439012',
        name: 'GDPR User',
        email: 'gdpr@example.com',
        password: 'Password123!',
        phone: '+1234567890',
      });

      await runMiddleware(userController.deleteAccount, mockReq, mockRes);

      const deletedUser = await User.findById(user._id);
      expect(deletedUser).toBeNull();
      expect(statusMock).toHaveBeenCalledWith(200);
      expect(jsonMock).toHaveBeenCalledWith(
        expect.objectContaining({
          status: 'success',
          message: expect.stringContaining('permanently deleted'),
        })
      );
    });
  });
});
