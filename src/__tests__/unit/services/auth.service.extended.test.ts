import { authService } from '../../../services/auth.service';
import User from '../../../models/User';
import Patient from '../../../models/Patient';
import { signupData, testUsers } from '../../fixtures/test.fixtures';
import { AppError } from '../../../utils/AppError';
import jwt from 'jsonwebtoken';
import { config } from '../../../config/config';

describe('Auth Service Extended Tests', () => {
  afterEach(async () => {
    await User.deleteMany({});
    await Patient.deleteMany({});
  });

  describe('Deactivated Account Login', () => {
    it('should throw a 403 AppError when trying to log in a deactivated user', async () => {
      // Create a user and deactivate them
      const user = await User.create({
        name: 'Deactivated User',
        email: 'deactivated@example.com',
        password: 'Password123!',
        phone: '+1234567890',
        isActive: false,
        role: 'user',
        isEmailVerified: true,
      });

      await expect(
        authService.login('deactivated@example.com', 'Password123!')
      ).rejects.toThrow(
        expect.objectContaining({
          statusCode: 403,
          message: 'User account is deactivated',
        })
      );
    });
  });

  describe('Signup Duplicate Email Status Code', () => {
    it('should throw a 409 AppError on duplicate email signup', async () => {
      await authService.signup(
        signupData.validSignup.name,
        signupData.validSignup.email,
        signupData.validSignup.password,
        signupData.validSignup.phone
      );

      await expect(
        authService.signup(
          'Another Name',
          signupData.validSignup.email,
          'AnotherPass123!',
          '+1234567899'
        )
      ).rejects.toThrow(
        expect.objectContaining({
          statusCode: 409,
          message: 'Email already registered',
        })
      );
    });
  });

  describe('JWT ID Security & Generation', () => {
    it('should generate tokens with cryptographically secure random hexadecimal jti claims', () => {
      const { accessToken, refreshToken } = authService.generateTokens(
        '507f1f77bcf86cd799439012',
        'user'
      );

      const accessPayload = jwt.verify(
        accessToken,
        config.jwt.secret
      ) as jwt.JwtPayload;

      const refreshPayload = jwt.verify(
        refreshToken,
        config.jwt.refreshSecret
      ) as jwt.JwtPayload;

      expect(accessPayload.jti).toBeDefined();
      expect(refreshPayload.jti).toBeDefined();
      expect(accessPayload.jti).toMatch(/^[0-9a-f]{32}$/i); // 16 bytes randomBytes = 32 hex chars
      expect(refreshPayload.jti).toMatch(/^[0-9a-f]{32}$/i);
      expect(accessPayload.jti).not.toBe(refreshPayload.jti);
    });
  });
});
