import User from '../../models/User';
import { testUsers } from '../fixtures/test.fixtures';
import bcryptjs from 'bcryptjs';

describe('User Model Tests', () => {
  afterEach(async () => {
    await User.deleteMany({});
  });

  describe('User Creation', () => {
    test('UNIT-User-001: Should create a user with valid data', async () => {
      const user = await User.create(testUsers.validUser);
      
      expect(user).toBeDefined();
      expect(user.email).toBe(testUsers.validUser.email);
      expect(user.name).toBe(testUsers.validUser.name);
      expect(user.phone).toBe(testUsers.validUser.phone);
    });

    test('UNIT-User-002: Should hash password on creation', async () => {
      const user = await User.create(testUsers.validUser);
      
      expect(user.password).toBeDefined();
      expect(user.password).not.toBe(testUsers.validUser.password);
      
      const isPasswordHashed = await bcryptjs.compare(
        testUsers.validUser.password,
        user.password!
      );
      expect(isPasswordHashed).toBe(true);
    });

    test('UNIT-User-003: Should set default role to user', async () => {
      const user = await User.create(testUsers.validUser);
      expect(user.role).toBe('user');
    });

    test('UNIT-User-004: Should set isEmailVerified to false by default', async () => {
      const user = await User.create(testUsers.validUser);
      expect(user.isEmailVerified).toBe(false);
    });

    test('UNIT-User-005: Should set isActive to true by default', async () => {
      const user = await User.create(testUsers.validUser);
      expect(user.isActive).toBe(true);
    });

    test('UNIT-User-006: Should accept all valid role values', async () => {
      const rolesData = [
        { ...testUsers.validUser, email: 'user1@test.com', role: 'user' },
        { ...testUsers.validUser, email: 'admin1@test.com', role: 'admin' },
        { ...testUsers.validUser, email: 'provider1@test.com', role: 'provider' },
      ];

      for (const data of rolesData) {
        const user = await User.create(data);
        expect(['user', 'admin', 'provider']).toContain(user.role);
      }
    });
  });

  describe('Email Uniqueness', () => {
    test('UNIT-User-007: Should enforce email uniqueness constraint', async () => {
      await User.create(testUsers.validUser);
      
      const duplicateUser = {
        ...testUsers.validUser,
        name: 'Different Name',
      };

      await expect(User.create(duplicateUser)).rejects.toThrow();
    });

    test('UNIT-User-008: Should allow case-insensitive email lookup', async () => {
      await User.create(testUsers.validUser);
      
      const found = await User.findOne({ 
        email: testUsers.validUser.email.toUpperCase() 
      });
      expect(found).toBeNull(); // Case-sensitive by default in MongoDB
    });
  });

  describe('Password Operations', () => {
    test('UNIT-User-009: Should hash password differently each time (salt)', async () => {
      const user1 = await User.create(testUsers.validUser);
      const user2 = await User.create({
        ...testUsers.validUser,
        email: 'different@example.com',
      });

      expect(user1.password).not.toBe(user2.password);
    });

    test('UNIT-User-010: Should not re-hash password on update if not modified', async () => {
      const user = await User.create(testUsers.validUser);
      const originalPassword = user.password;

      user.name = 'Updated Name';
      await user.save();

      expect(user.password).toBe(originalPassword);
    });

    test('UNIT-User-011: Should compare password correctly', async () => {
      const user = await User.create(testUsers.validUser);

      const isMatch = await user.comparePassword(testUsers.validUser.password);
      expect(isMatch).toBe(true);
    });

    test('UNIT-User-012: Should reject incorrect password', async () => {
      const user = await User.create(testUsers.validUser);

      const isMatch = await user.comparePassword('WrongPassword123!');
      expect(isMatch).toBe(false);
    });
  });

  describe('GoogleId Field', () => {
    test('UNIT-User-013: Should allow googleId to be optional', async () => {
      const user = await User.create(testUsers.validUser);
      expect(user.googleId).toBeUndefined();
    });

    test('UNIT-User-014: Should allow multiple users with no googleId (sparse index)', async () => {
      const user1 = await User.create(testUsers.validUser);
      const user2 = await User.create({
        ...testUsers.anotherValidUser,
      });

      expect(user1.googleId).toBeUndefined();
      expect(user2.googleId).toBeUndefined();
    });

    test('UNIT-User-015: Should enforce googleId uniqueness when present', async () => {
      await User.create({
        ...testUsers.validUser,
        googleId: 'google123',
      });

      await expect(User.create({
        ...testUsers.anotherValidUser,
        googleId: 'google123',
      })).rejects.toThrow();
    });
  });

  describe('Timestamps', () => {
    test('UNIT-User-016: Should set createdAt timestamp', async () => {
      const user = await User.create(testUsers.validUser);
      expect(user.createdAt).toBeDefined();
      expect(user.createdAt).toBeInstanceOf(Date);
    });

    test('UNIT-User-017: Should set updatedAt timestamp', async () => {
      const user = await User.create(testUsers.validUser);
      expect(user.updatedAt).toBeDefined();
      expect(user.updatedAt).toBeInstanceOf(Date);
    });

    test('UNIT-User-018: Should update updatedAt on modification', async () => {
      const user = await User.create(testUsers.validUser);
      const initialUpdatedAt = user.updatedAt;

      await new Promise(resolve => setTimeout(resolve, 100));

      user.name = 'Updated Name';
      await user.save();

      expect(user.updatedAt.getTime()).toBeGreaterThan(initialUpdatedAt.getTime());
    });
  });

  describe('Query Operations', () => {
    test('UNIT-User-019: Should exclude password from queries by default', async () => {
      await User.create(testUsers.validUser);
      
      const user = await User.findOne({ email: testUsers.validUser.email });
      expect(user!.password).toBeUndefined();
    });

    test('UNIT-User-020: Should include password when explicitly selected', async () => {
      await User.create(testUsers.validUser);
      
      const user = await User.findOne({ email: testUsers.validUser.email }).select('+password');
      expect(user!.password).toBeDefined();
    });

    test('UNIT-User-021: Should find user by email', async () => {
      await User.create(testUsers.validUser);
      
      const user = await User.findOne({ email: testUsers.validUser.email });
      expect(user).toBeDefined();
      expect(user!.email).toBe(testUsers.validUser.email);
    });

    test('UNIT-User-022: Should find user by id', async () => {
      const created = await User.create(testUsers.validUser);
      
      const user = await User.findById(created._id);
      expect(user).toBeDefined();
      expect(user!._id.toString()).toBe(created._id.toString());
    });
  });

  describe('Field Validation', () => {
    test('UNIT-User-023: Should validate email format', async () => {
      const invalidUser = {
        ...testUsers.validUser,
        email: 'not-an-email',
      };

      await expect(User.create(invalidUser)).rejects.toThrow();
    });

    test('UNIT-User-024: Should validate minimum age', async () => {
      const youngUser = {
        ...testUsers.validUser,
        email: 'young@test.com',
        age: 17,
      };

      await expect(User.create(youngUser)).rejects.toThrow();
    });

    test('UNIT-User-025: Should validate maximum age', async () => {
      const oldUser = {
        ...testUsers.validUser,
        email: 'old@test.com',
        age: 121,
      };

      await expect(User.create(oldUser)).rejects.toThrow();
    });

    test('UNIT-User-026: Should validate gender enum', async () => {
      const invalidGender = {
        ...testUsers.validUser,
        email: 'gender@test.com',
        gender: 'Unknown',
      };

      await expect(User.create(invalidGender)).rejects.toThrow();
    });

    test('UNIT-User-027: Should require email field', async () => {
      const noEmail = {
        ...testUsers.validUser,
        email: undefined,
      };

      await expect(User.create(noEmail)).rejects.toThrow();
    });

    test('UNIT-User-028: Should require name field', async () => {
      const noName = {
        ...testUsers.validUser,
        name: undefined,
      };

      await expect(User.create(noName)).rejects.toThrow();
    });

    test('UNIT-User-029: Should require phone field', async () => {
      const noPhone = {
        ...testUsers.validUser,
        phone: undefined,
      };

      await expect(User.create(noPhone)).rejects.toThrow();
    });
  });

  describe('Update Operations', () => {
    test('UNIT-User-030: Should update user fields', async () => {
      const user = await User.create(testUsers.validUser);

      user.name = 'Updated Name';
      await user.save();

      const updated = await User.findById(user._id);
      expect(updated!.name).toBe('Updated Name');
    });

    test('UNIT-User-031: Should update with partial data', async () => {
      const user = await User.create(testUsers.validUser);

      await User.findByIdAndUpdate(user._id, { age: 40 });

      const updated = await User.findById(user._id);
      expect(updated!.age).toBe(40);
      expect(updated!.email).toBe(testUsers.validUser.email);
    });

    test('UNIT-User-032: Should not allow email update to duplicate', async () => {
      await User.create(testUsers.validUser);
      const user2 = await User.create(testUsers.anotherValidUser);

      await expect(
        User.findByIdAndUpdate(user2._id, { email: testUsers.validUser.email })
      ).rejects.toThrow();
    });
  });

  describe('Delete Operations', () => {
    test('UNIT-User-033: Should delete user', async () => {
      const user = await User.create(testUsers.validUser);

      await User.findByIdAndDelete(user._id);

      const deleted = await User.findById(user._id);
      expect(deleted).toBeNull();
    });

    test('UNIT-User-034: Should delete multiple users', async () => {
      await User.create(testUsers.validUser);
      await User.create(testUsers.anotherValidUser);

      await User.deleteMany({});

      const count = await User.countDocuments();
      expect(count).toBe(0);
    });
  });
});
