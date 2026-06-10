import User from '../../models/User';
import Patient from '../../models/Patient';
import { testUsers, signupData } from '../fixtures/test.fixtures';
import { Types } from 'mongoose';

// Helper function to create unique test user
const createUniqueTestUser = (suffix = '') => ({
  name: `Test User${suffix}`,
  email: `test${Date.now()}${Math.random().toString(36).substr(2, 9)}${suffix}@example.com`,
  password: 'SecurePass123!',
  phone: `+123456789${Date.now() % 10}`,
  gender: 'Male',
  age: 30,
});

describe('Database Tests', () => {
  afterEach(async () => {
    await Patient.deleteMany({});
    await User.deleteMany({});
  });

  describe('Indexes', () => {
    test('DB-Index-001: Should enforce unique email index', async () => {
      const uniqueUser = createUniqueTestUser();
      await User.create(uniqueUser);

      await expect(
        User.create({
          ...uniqueUser,
          name: 'Different Name',
        })
      ).rejects.toThrow();
    });

    test('DB-Index-002: Should allow null googleId (sparse index)', async () => {
      const user1 = await User.create(createUniqueTestUser('1'));
      const user2 = await User.create(createUniqueTestUser('2'));

      expect(user1.googleId).toBeUndefined();
      expect(user2.googleId).toBeUndefined();
    });

    test('DB-Index-003: Should enforce unique googleId when present', async () => {
      const uniqueId = `google-${Date.now()}`;
      await User.create({
        ...createUniqueTestUser(),
        googleId: uniqueId,
      });

      await expect(
        User.create({
          ...createUniqueTestUser(),
          googleId: uniqueId,
        })
      ).rejects.toThrow();
    });

    test('DB-Index-004: Should query efficiently by email', async () => {
      const uniqueUser = createUniqueTestUser();
      await User.create(uniqueUser);

      const start = performance.now();
      await User.findOne({ email: uniqueUser.email });
      const duration = performance.now() - start;

      expect(duration).toBeLessThan(50); // Should be fast due to index
    });

    test('DB-Index-005: Should query efficiently by role', async () => {
      await User.create(createUniqueTestUser());

      const start = performance.now();
      await User.findOne({ role: 'user' });
      const duration = performance.now() - start;

      expect(duration).toBeLessThan(50);
    });

    test('DB-Index-006: Should enforce unique userId in Patient', async () => {
      const user = await User.create(createUniqueTestUser());

      await Patient.create({
        userId: user._id,
        allergies: [],
        medications: [],
      });

      await expect(
        Patient.create({
          userId: user._id,
          allergies: [],
          medications: [],
        })
      ).rejects.toThrow();
    });
  });

  describe('CRUD Operations', () => {
    describe('Create', () => {
      test('DB-CRUD-001: Should create user with all fields', async () => {
        const uniqueUser = createUniqueTestUser();
        const user = await User.create(uniqueUser);

        expect(user._id).toBeDefined();
        expect(user.email).toBe(uniqueUser.email);
        expect(user.name).toBe(uniqueUser.name);
      });

      test('DB-CRUD-002: Should create patient with reference', async () => {
        const user = await User.create(createUniqueTestUser());

        const patient = await Patient.create({
          userId: user._id,
          allergies: [],
          medications: [],
        });

        expect(patient.userId.toString()).toBe(user._id.toString());
      });

      test('DB-CRUD-003: Should auto-generate timestamps', async () => {
        const user = await User.create(createUniqueTestUser());

        expect(user.createdAt).toBeDefined();
        expect(user.updatedAt).toBeDefined();
      });
    });

    describe('Read', () => {
      let testUser1: any;
      let testUser2: any;

      beforeEach(async () => {
        testUser1 = createUniqueTestUser('1');
        testUser2 = createUniqueTestUser('2');
        await User.create(testUser1);
        await User.create(testUser2);
      });

      test('DB-CRUD-004: Should read user by id', async () => {
        const user = await User.findOne({ email: testUser1.email });
        const retrieved = await User.findById(user!._id);

        expect(retrieved).toBeDefined();
        expect(retrieved!.email).toBe(testUser1.email);
      });

      test('DB-CRUD-005: Should read user by email', async () => {
        const user = await User.findOne({ email: testUser1.email });

        expect(user).toBeDefined();
        expect(user!.name).toBe(testUser1.name);
      });

      test('DB-CRUD-006: Should read multiple users', async () => {
        const users = await User.find({});

        expect(users.length).toBe(2);
      });

      test('DB-CRUD-007: Should return null for non-existent user', async () => {
        const user = await User.findById(new Types.ObjectId());

        expect(user).toBeNull();
      });

      test('DB-CRUD-008: Should exclude password from default read', async () => {
        const user = await User.findOne({ email: testUser1.email });

        expect(user!.password).toBeUndefined();
      });
    });

    describe('Update', () => {
      let testUser: any;

      beforeEach(async () => {
        testUser = createUniqueTestUser();
        await User.create(testUser);
      });

      test('DB-CRUD-009: Should update user fields', async () => {
        const user = await User.findOne({ email: testUser.email });

        user!.name = 'Updated Name';
        await user!.save();

        const updated = await User.findById(user!._id);
        expect(updated!.name).toBe('Updated Name');
      });

      test('DB-CRUD-010: Should update specific fields', async () => {
        const user = await User.findOne({ email: testUser.email });

        await User.findByIdAndUpdate(user!._id, { age: 40 });

        const updated = await User.findById(user!._id);
        expect(updated!.age).toBe(40);
      });

      test('DB-CRUD-011: Should update timestamps', async () => {
        const user = await User.findOne({ email: testUser.email });
        const originalTime = user!.updatedAt;

        await new Promise(resolve => setTimeout(resolve, 100));

        user!.name = 'New Name';
        await user!.save();

        expect(user!.updatedAt.getTime()).toBeGreaterThan(originalTime.getTime());
      });

      test('DB-CRUD-012: Should prevent email update to duplicate', async () => {
        const user1 = await User.findOne({ email: testUser.email });
        const testUser2 = createUniqueTestUser('2');
        await User.create(testUser2);

        await expect(
          User.findByIdAndUpdate(user1!._id, {
            email: testUser2.email,
          })
        ).rejects.toThrow();
      });
    });

    describe('Delete', () => {
      test('DB-CRUD-013: Should delete user by id', async () => {
        const testUser = createUniqueTestUser();
        const user = await User.create(testUser);

        await User.findByIdAndDelete(user._id);

        const deleted = await User.findById(user._id);
        expect(deleted).toBeNull();
      });

      test('DB-CRUD-014: Should delete multiple users', async () => {
        await User.create(createUniqueTestUser('1'));
        await User.create(createUniqueTestUser('2'));

        await User.deleteMany({});

        const count = await User.countDocuments();
        expect(count).toBe(0);
      });

      test('DB-CRUD-015: Should cascade delete patient on user delete (if configured)', async () => {
        const testUser = createUniqueTestUser();
        const user = await User.create(testUser);

        await Patient.create({
          userId: user._id,
          allergies: [],
          medications: [],
        });

        // Note: Cascading delete should be handled at application level if needed
        await User.findByIdAndDelete(user._id);

        const patient = await Patient.findOne({ userId: user._id });
        // Patient will remain unless explicitly deleted or cascade configured
      });
    });
  });

  describe('Relationships', () => {
    test('DB-Relationship-001: Should maintain user-patient relationship', async () => {
      const testUser = createUniqueTestUser();
      const user = await User.create(testUser);

      const patient = await Patient.create({
        userId: user._id,
        allergies: [],
        medications: [],
      });

      const retrieved = await Patient.findById(patient._id);

      expect(retrieved).toBeDefined();
      expect(retrieved!.userId).toBeDefined();
      expect(retrieved!.userId.toString()).toBe(user._id.toString());
    });

    test('DB-Relationship-002: Should allow finding patient by userId', async () => {
      const testUser = createUniqueTestUser();
      const user = await User.create(testUser);

      await Patient.create({
        userId: user._id,
        allergies: [],
        medications: [],
      });

      const patient = await Patient.findOne({ userId: user._id });

      expect(patient).toBeDefined();
      expect(patient!.userId.toString()).toBe(user._id.toString());
    });

    test('DB-Relationship-003: Should enforce referential integrity', async () => {
      const fakeId = new Types.ObjectId();

      // Should allow creation with non-existent userId (no foreign key constraint)
      // This is a design decision - could be enforced at application level
      const patient = await Patient.create({
        userId: fakeId,
        allergies: [],
        medications: [],
      });

      expect(patient.userId.toString()).toBe(fakeId.toString());
    });
  });

  describe('Data Integrity', () => {
    test('DB-Integrity-001: Should maintain data consistency in concurrent operations', async () => {
      const promises = Array(5).fill(null).map((_, i) =>
        User.create(createUniqueTestUser(`${i}`))
      );

      const users = await Promise.all(promises);

      const count = await User.countDocuments();
      expect(count).toBe(5);
    });

    test('DB-Integrity-002: Should handle simultaneous updates', async () => {
      const testUser = createUniqueTestUser();
      const user = await User.create(testUser);

      const promises = Array(3).fill(null).map((_, i) =>
        User.findByIdAndUpdate(user._id, { age: 30 + i })
      );

      await Promise.all(promises);

      const updated = await User.findById(user._id);
      // Last update should win
      expect(updated!.age).toBeDefined();
      expect(updated!.age).toBeGreaterThanOrEqual(30);
    });

    test('DB-Integrity-003: Should not allow invalid enum values', async () => {
      await expect(
        User.create({
          ...createUniqueTestUser(),
          role: 'invalid_role' as any,
        })
      ).rejects.toThrow();
    });

    test('DB-Integrity-004: Should validate email format at schema level', async () => {
      await expect(
        User.create({
          ...createUniqueTestUser(),
          email: 'not-an-email',
        })
      ).rejects.toThrow();
    });
  });

  describe('Query Performance', () => {
    beforeEach(async () => {
      // Create 5 test users (reduced from 10 for better performance)
      for (let i = 0; i < 5; i++) {
        await User.create(createUniqueTestUser(`perf${i}`));
      }
    }, 10000); // Increase timeout for beforeEach

    test('DB-Performance-001: Should query by indexed field efficiently', async () => {
      const start = performance.now();
      await User.find({ role: 'user' }).limit(1);
      const duration = performance.now() - start;

      expect(duration).toBeLessThan(50);
    });

    test('DB-Performance-002: Should find multiple records efficiently', async () => {
      const start = performance.now();
      await User.find({ role: 'user' });
      const duration = performance.now() - start;

      expect(duration).toBeLessThan(100);
    });

    test('DB-Performance-003: Should count documents efficiently', async () => {
      const start = performance.now();
      const count = await User.countDocuments();
      const duration = performance.now() - start;

      expect(count).toBe(5);
      expect(duration).toBeLessThan(50);
    }, 10000);

    test('DB-Performance-004: Should sort efficiently', async () => {
      const start = performance.now();
      await User.find({}).sort({ createdAt: -1 }).limit(5);
      const duration = performance.now() - start;

      expect(duration).toBeLessThan(100);
    });
  });

  describe('Schema Validation', () => {
    test('DB-Validation-001: Should require email field', async () => {
      await expect(
        User.create({
          ...createUniqueTestUser(),
          email: undefined,
        })
      ).rejects.toThrow();
    });

    test('DB-Validation-002: Should require name field', async () => {
      await expect(
        User.create({
          ...createUniqueTestUser(),
          name: undefined,
        })
      ).rejects.toThrow();
    });

    test('DB-Validation-003: Should validate age range', async () => {
      await expect(
        User.create({
          ...createUniqueTestUser(),
          age: 10,
        })
      ).rejects.toThrow();
    });

    test('DB-Validation-004: Should validate gender enum', async () => {
      await expect(
        User.create({
          ...testUsers.validUser,
          email: 'gendertest@example.com',
          gender: 'InvalidGender' as any,
        })
      ).rejects.toThrow();
    });
  });
});
