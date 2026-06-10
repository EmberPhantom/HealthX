import {
  signupSchema,
  loginSchema,
  googleAuthSchema,
  refreshTokenSchema,
  updateProfileSchema,
} from '../../schemas/auth.schema';
import { signupData, loginCredentials, profileUpdates } from '../fixtures/test.fixtures';
import { ZodError } from 'zod';

describe('Validation Schemas Tests', () => {
  describe('Signup Schema', () => {
    test('VAL-Schema-001: Should validate correct signup data', () => {
      const result = signupSchema.safeParse(signupData.validSignup);
      expect(result.success).toBe(true);
    });

    test('VAL-Schema-002: Should reject weak password', () => {
      const result = signupSchema.safeParse({
        ...signupData.validSignup,
        password: 'weak',
        confirmPassword: 'weak',
      });
      expect(result.success).toBe(false);
    });

    test('VAL-Schema-003: Should reject mismatched passwords', () => {
      const result = signupSchema.safeParse(signupData.mismatchedPasswords);
      expect(result.success).toBe(false);
    });

    test('VAL-Schema-004: Should reject invalid email', () => {
      const result = signupSchema.safeParse({
        ...signupData.validSignup,
        email: 'not-an-email',
      });
      expect(result.success).toBe(false);
    });

    test('VAL-Schema-005: Should reject password without uppercase', () => {
      const result = signupSchema.safeParse(signupData.noUppercase);
      expect(result.success).toBe(false);
    });

    test('VAL-Schema-006: Should reject password without number', () => {
      const result = signupSchema.safeParse({
        ...signupData.validSignup,
        password: 'TestPass!',
        confirmPassword: 'TestPass!',
      });
      expect(result.success).toBe(false);
    });

    test('VAL-Schema-007: Should reject password without special character', () => {
      const result = signupSchema.safeParse(signupData.noSpecialChar);
      expect(result.success).toBe(false);
    });

    test('VAL-Schema-008: Should require all fields', () => {
      const result = signupSchema.safeParse({
        name: 'Test',
        email: 'test@example.com',
      });
      expect(result.success).toBe(false);
    });

    test('VAL-Schema-009: Should provide error messages', () => {
      const result = signupSchema.safeParse({
        ...signupData.validSignup,
        password: 'weak',
        confirmPassword: 'weak',
      });
      
      if (!result.success) {
        expect(result.error.issues.length).toBeGreaterThan(0);
        expect(result.error.issues[0].message).toBeDefined();
      }
    });

    test('VAL-Schema-010: Should accept valid phone number', () => {
      const result = signupSchema.safeParse(signupData.validSignup);
      expect(result.success).toBe(true);
    });
  });

  describe('Login Schema', () => {
    test('VAL-Schema-011: Should validate correct login data', () => {
      const result = loginSchema.safeParse(loginCredentials.validLogin);
      expect(result.success).toBe(true);
    });

    test('VAL-Schema-012: Should require email', () => {
      const result = loginSchema.safeParse({
        password: 'password123',
      });
      expect(result.success).toBe(false);
    });

    test('VAL-Schema-013: Should require password', () => {
      const result = loginSchema.safeParse({
        email: 'test@example.com',
      });
      expect(result.success).toBe(false);
    });

    test('VAL-Schema-014: Should validate email format', () => {
      const result = loginSchema.safeParse({
        email: 'invalid-email',
        password: 'ValidPass123!',
      });
      expect(result.success).toBe(false);
    });

    test('VAL-Schema-015: Should require both fields', () => {
      const result = loginSchema.safeParse({});
      expect(result.success).toBe(false);
    });
  });

  describe('Google Auth Schema', () => {
    test('VAL-Schema-016: Should validate token', () => {
      const result = googleAuthSchema.safeParse({
        idToken: 'valid-google-token-string',
      });
      expect(result.success).toBe(true);
    });

    test('VAL-Schema-017: Should require token', () => {
      const result = googleAuthSchema.safeParse({});
      expect(result.success).toBe(false);
    });

    test('VAL-Schema-018: Should reject empty token', () => {
      const result = googleAuthSchema.safeParse({
        idToken: '',
      });
      expect(result.success).toBe(false);
    });
  });

  describe('Refresh Token Schema', () => {
    test('VAL-Schema-019: Should validate refresh token', () => {
      const result = refreshTokenSchema.safeParse({
        refreshToken: 'valid-jwt-token-string',
      });
      expect(result.success).toBe(true);
    });

    test('VAL-Schema-020: Should require refresh token', () => {
      const result = refreshTokenSchema.safeParse({});
      expect(result.success).toBe(false);
    });

    test('VAL-Schema-021: Should reject empty token', () => {
      const result = refreshTokenSchema.safeParse({
        refreshToken: '',
      });
      expect(result.success).toBe(false);
    });
  });

  describe('Update Profile Schema', () => {
    test('VAL-Schema-022: Should validate update data', () => {
      const result = updateProfileSchema.safeParse(profileUpdates.validUpdate);
      expect(result.success).toBe(true);
    });

    test('VAL-Schema-023: Should allow partial updates', () => {
      const result = updateProfileSchema.safeParse({
        name: 'Updated Name',
      });
      expect(result.success).toBe(true);
    });

    test('VAL-Schema-024: Should validate age minimum', () => {
      const result = updateProfileSchema.safeParse({
        age: 17,
      });
      expect(result.success).toBe(false);
    });

    test('VAL-Schema-025: Should validate age maximum', () => {
      const result = updateProfileSchema.safeParse({
        age: 121,
      });
      expect(result.success).toBe(false);
    });

    test('VAL-Schema-026: Should accept age at boundaries', () => {
      const result1 = updateProfileSchema.safeParse({ age: 18 });
      const result2 = updateProfileSchema.safeParse({ age: 120 });
      
      expect(result1.success).toBe(true);
      expect(result2.success).toBe(true);
    });

    test('VAL-Schema-027: Should validate gender enum', () => {
      const validGenders = ['Male', 'Female', 'Others'];
      
      for (const gender of validGenders) {
        const result = updateProfileSchema.safeParse({ gender });
        expect(result.success).toBe(true);
      }
    });

    test('VAL-Schema-028: Should reject invalid gender', () => {
      const result = updateProfileSchema.safeParse({
        gender: 'InvalidGender',
      });
      expect(result.success).toBe(false);
    });

    test('VAL-Schema-029: Should allow empty object', () => {
      const result = updateProfileSchema.safeParse({});
      expect(result.success).toBe(true);
    });

    test('VAL-Schema-030: Should validate phone format if provided', () => {
      const result = updateProfileSchema.safeParse({
        phone: '+1234567890',
      });
      expect(result.success).toBe(true);
    });
  });
});
