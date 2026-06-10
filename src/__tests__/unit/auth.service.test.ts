import { authService } from '../../services/auth.service';
import User from '../../models/User';
import Patient from '../../models/Patient';
import { testUsers, generateTestTokens, loginCredentials, signupData } from '../fixtures/test.fixtures';

describe('Auth Service Tests', () => {
  afterEach(async () => {
    await User.deleteMany({});
    await Patient.deleteMany({});
  });

  describe('Signup', () => {
    test('UNIT-AuthService-001: Should signup user successfully', async () => {
      const result = await authService.signup(
        signupData.validSignup.name,
        signupData.validSignup.email,
        signupData.validSignup.password,
        signupData.validSignup.phone
      );

      expect(result).toBeDefined();
      expect(result.accessToken).toBeDefined();
      expect(result.refreshToken).toBeDefined();
      expect(result.user.email).toBe(signupData.validSignup.email);
    });

    test('UNIT-AuthService-002: Should create patient profile on signup', async () => {
      await authService.signup(
        signupData.validSignup.name,
        signupData.validSignup.email,
        signupData.validSignup.password,
        signupData.validSignup.phone
      );

      const user = await User.findOne({ email: signupData.validSignup.email });
      const patient = await Patient.findOne({ userId: user!._id });

      expect(patient).toBeDefined();
      expect(patient!.userId.toString()).toBe(user!._id.toString());
    });

    test('UNIT-AuthService-003: Should reject duplicate email', async () => {
      await authService.signup(
        testUsers.validUser.name,
        testUsers.validUser.email,
        testUsers.validUser.password,
        testUsers.validUser.phone
      );

      await expect(
        authService.signup(
          'Different Name',
          testUsers.validUser.email,
          'DifferentPass123!',
          testUsers.validUser.phone
        )
      ).rejects.toThrow('Email already registered');
    });

    test('UNIT-AuthService-004: Should return valid tokens', async () => {
      const result = await authService.signup(
        signupData.validSignup.name,
        signupData.validSignup.email,
        signupData.validSignup.password,
        signupData.validSignup.phone
      );

      expect(result.accessToken).toMatch(/^eyJ/); // JWT pattern
      expect(result.refreshToken).toMatch(/^eyJ/);
      expect(result.expiresAt).toBeDefined();
    });

    test('UNIT-AuthService-005: Should return user data in response', async () => {
      const result = await authService.signup(
        signupData.validSignup.name,
        signupData.validSignup.email,
        signupData.validSignup.password,
        signupData.validSignup.phone
      );

      expect(result.user).toBeDefined();
      expect(result.user.email).toBe(signupData.validSignup.email);
      expect(result.user.name).toBe(signupData.validSignup.name);
      expect(result.user.role).toBe('user');
    });
  });

  describe('Login', () => {
    beforeEach(async () => {
      await authService.signup(
        testUsers.validUser.name,
        testUsers.validUser.email,
        testUsers.validUser.password,
        testUsers.validUser.phone
      );
    });

    test('UNIT-AuthService-006: Should login with valid credentials', async () => {
      const result = await authService.login(
        testUsers.validUser.email,
        testUsers.validUser.password
      );

      expect(result).toBeDefined();
      expect(result.accessToken).toBeDefined();
      expect(result.refreshToken).toBeDefined();
    });

    test('UNIT-AuthService-007: Should reject invalid email', async () => {
      await expect(
        authService.login('nonexistent@example.com', testUsers.validUser.password)
      ).rejects.toThrow('Invalid email or password');
    });

    test('UNIT-AuthService-008: Should reject invalid password', async () => {
      await expect(
        authService.login(testUsers.validUser.email, 'WrongPassword123!')
      ).rejects.toThrow('Invalid email or password');
    });

    test('UNIT-AuthService-009: Should reject inactive user', async () => {
      const user = await User.findOne({ email: testUsers.validUser.email });
      user!.isActive = false;
      await user!.save();

      await expect(
        authService.login(testUsers.validUser.email, testUsers.validUser.password)
      ).rejects.toThrow('User account is deactivated');
    });

    test('UNIT-AuthService-010: Should return valid tokens on login', async () => {
      const result = await authService.login(
        testUsers.validUser.email,
        testUsers.validUser.password
      );

      expect(result.accessToken).toMatch(/^eyJ/);
      expect(result.refreshToken).toMatch(/^eyJ/);
    });
  });

  describe('Token Generation', () => {
    test('UNIT-AuthService-011: Should generate access and refresh tokens', async () => {
      const userId = '507f1f77bcf86cd799439012';
      const { accessToken, refreshToken } = authService.generateTokens(userId, 'user');

      expect(accessToken).toBeDefined();
      expect(refreshToken).toBeDefined();
      expect(accessToken).not.toBe(refreshToken);
    });

    test('UNIT-AuthService-012: Should include user claims in token', async () => {
      const userId = '507f1f77bcf86cd799439012';
      const role = 'admin';
      const { accessToken } = authService.generateTokens(userId, role);

      const payload = authService.verifyToken(accessToken, 'access');
      expect(payload.userId).toBe(userId);
      expect(payload.role).toBe(role);
    });

    test('UNIT-AuthService-013: Should set token expiration', async () => {
      const userId = '507f1f77bcf86cd799439012';
      const { expiresAt } = authService.generateTokens(userId, 'user');

      const expirationTime = new Date(expiresAt).getTime();
      const currentTime = Date.now();

      expect(expirationTime).toBeGreaterThan(currentTime);
    });
  });

  describe('Token Verification', () => {
    test('UNIT-AuthService-014: Should verify valid token', async () => {
      const tokens = generateTestTokens();
      const payload = authService.verifyToken(tokens.accessToken, 'access');

      expect(payload).toBeDefined();
      expect(payload.userId).toBe(tokens.userId);
    });

    test('UNIT-AuthService-015: Should reject expired token', async () => {
      const tokens = generateTestTokens();

      expect(() =>
        authService.verifyToken(tokens.expiredToken, 'access')
      ).toThrow('Token has expired');
    });

    test('UNIT-AuthService-016: Should reject invalid token', async () => {
      const tokens = generateTestTokens();

      expect(() =>
        authService.verifyToken(tokens.invalidToken, 'access')
      ).toThrow();
    });

    test('UNIT-AuthService-017: Should verify refresh token separately', async () => {
      const userId = '507f1f77bcf86cd799439012';
      const { refreshToken } = authService.generateTokens(userId, 'user');

      const payload = authService.verifyToken(refreshToken, 'refresh');
      expect(payload.userId).toBe(userId);
    });
  });

  describe('Token Refresh', () => {
    beforeEach(async () => {
      await authService.signup(
        testUsers.validUser.name,
        testUsers.validUser.email,
        testUsers.validUser.password,
        testUsers.validUser.phone
      );
    });

    test('UNIT-AuthService-018: Should refresh token successfully', async () => {
      const loginResult = await authService.login(
        testUsers.validUser.email,
        testUsers.validUser.password
      );

      const refreshResult = await authService.refreshToken(loginResult.refreshToken);

      expect(refreshResult.accessToken).toBeDefined();
      expect(refreshResult.expiresAt).toBeDefined();
      expect(refreshResult.accessToken).not.toBe(loginResult.accessToken);
    });

    test('UNIT-AuthService-019: Should reject invalid refresh token', async () => {
      const tokens = generateTestTokens();

      await expect(
        authService.refreshToken(tokens.invalidToken)
      ).rejects.toThrow();
    });

    test('UNIT-AuthService-020: Should reject expired refresh token', async () => {
      const tokens = generateTestTokens();

      await expect(
        authService.refreshToken(tokens.expiredToken)
      ).rejects.toThrow();
    });
  });

  describe('Logout', () => {
    beforeEach(async () => {
      await authService.signup(
        testUsers.validUser.name,
        testUsers.validUser.email,
        testUsers.validUser.password,
        testUsers.validUser.phone
      );
    });

    test('UNIT-AuthService-021: Should logout successfully', async () => {
      const loginResult = await authService.login(
        testUsers.validUser.email,
        testUsers.validUser.password
      );

      await expect(
        authService.logout(loginResult.refreshToken)
      ).resolves.not.toThrow();
    });

    test('UNIT-AuthService-022: Should blacklist token on logout', async () => {
      const loginResult = await authService.login(
        testUsers.validUser.email,
        testUsers.validUser.password
      );

      await authService.logout(loginResult.refreshToken);

      // Attempting to use blacklisted token should fail
      await expect(
        authService.refreshToken(loginResult.refreshToken)
      ).rejects.toThrow('Token has been revoked');
    });

    test('UNIT-AuthService-023: Should reject invalid token on logout', async () => {
      const tokens = generateTestTokens();

      await expect(
        authService.logout(tokens.invalidToken)
      ).rejects.toThrow();
    });
  });

  describe('Get User By ID', () => {
    beforeEach(async () => {
      await authService.signup(
        testUsers.validUser.name,
        testUsers.validUser.email,
        testUsers.validUser.password,
        testUsers.validUser.phone
      );
    });

    test('UNIT-AuthService-024: Should get user by id', async () => {
      const user = await User.findOne({ email: testUsers.validUser.email });
      const retrieved = await authService.getUserById(user!._id.toString());

      expect(retrieved).toBeDefined();
      expect(retrieved!.email).toBe(testUsers.validUser.email);
    });

    test('UNIT-AuthService-025: Should return null for non-existent user', async () => {
      const user = await authService.getUserById('507f1f77bcf86cd799439013');

      expect(user).toBeNull();
    });
  });

  describe('Update Profile', () => {
    beforeEach(async () => {
      await authService.signup(
        testUsers.validUser.name,
        testUsers.validUser.email,
        testUsers.validUser.password,
        testUsers.validUser.phone
      );
    });

    test('UNIT-AuthService-026: Should update user profile', async () => {
      const user = await User.findOne({ email: testUsers.validUser.email });

      const updated = await authService.updateProfile(user!._id.toString(), {
        name: 'Updated Name',
        age: 35,
      });

      expect(updated.name).toBe('Updated Name');
      expect(updated.age).toBe(35);
    });

    test('UNIT-AuthService-027: Should update partial fields', async () => {
      const user = await User.findOne({ email: testUsers.validUser.email });

      const updated = await authService.updateProfile(user!._id.toString(), {
        age: 40,
      });

      expect(updated.age).toBe(40);
      expect(updated.name).toBe(testUsers.validUser.name);
    });

    test('UNIT-AuthService-028: Should reject non-existent user', async () => {
      await expect(
        authService.updateProfile('507f1f77bcf86cd799439013', { name: 'Test' })
      ).rejects.toThrow('User not found');
    });
  });

  describe('Google Auth Handler', () => {
    test('UNIT-AuthService-029: Should handle Google profile', async () => {
      const googleProfile = {
        googleId: 'google123',
        name: 'Google User',
        email: 'googleuser@example.com',
        avatarUrl: 'https://example.com/photo.jpg',
      };

      const result = await authService.handleGoogleAuth(googleProfile);

      expect(result).toBeDefined();
      expect(result.accessToken).toBeDefined();
      expect(result.user.email).toBe('googleuser@example.com');
    });

    test('UNIT-AuthService-030: Should link Google to existing account', async () => {
      // Create user first
      await authService.signup(
        testUsers.validUser.name,
        testUsers.validUser.email,
        testUsers.validUser.password,
        testUsers.validUser.phone
      );

      // Now link Google auth
      const googleProfile = {
        googleId: 'google123',
        name: 'Different Name',
        email: testUsers.validUser.email,
        avatarUrl: 'https://example.com/photo.jpg',
      };

      const result = await authService.handleGoogleAuth(googleProfile);

      const user = await User.findOne({ email: testUsers.validUser.email });
      expect(user!.googleId).toBe('google123');
      expect(result.user.email).toBe(testUsers.validUser.email);
    });

    test('UNIT-AuthService-031: Should create new user from Google profile', async () => {
      const googleProfile = {
        googleId: 'google123',
        name: 'New Google User',
        email: 'newgoogleuser@example.com',
        avatarUrl: 'https://example.com/photo.jpg',
      };

      const result = await authService.handleGoogleAuth(googleProfile);

      const user = await User.findOne({ email: 'newgoogleuser@example.com' });
      expect(user).toBeDefined();
      expect(user!.googleId).toBe('google123');
      expect(user!.isEmailVerified).toBe(true);
    });
  });
});
