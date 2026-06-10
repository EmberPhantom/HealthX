import jwt from 'jsonwebtoken';
import { config } from '../../config/config';

// Test user fixtures
export const testUsers = {
  validUser: {
    name: 'John Doe',
    email: 'john@example.com',
    password: 'SecurePass123!',
    phone: '+1234567890',
    gender: 'Male',
    age: 30,
  },
  
  anotherValidUser: {
    name: 'Jane Smith',
    email: 'jane@example.com',
    password: 'AnotherPass456!',
    phone: '+0987654321',
    gender: 'Female',
    age: 28,
  },
  
  invalidPassword: {
    name: 'Bob Wilson',
    email: 'bob@example.com',
    password: 'weak',
    phone: '+1122334455',
  },
  
  invalidEmail: {
    name: 'Alice Brown',
    email: 'invalid-email',
    password: 'ValidPass123!',
    phone: '+5566778899',
  },
  
  missingFields: {
    name: 'Incomplete User',
    email: 'incomplete@example.com',
  },
  
  duplicateEmail: {
    name: 'Duplicate Test',
    email: 'john@example.com', // Same as testUsers.validUser
    password: 'DifferentPass789!',
    phone: '+9988776655',
  },

  specialCharsName: {
    name: "O'Brien-Smith",
    email: 'special@example.com',
    password: 'ValidPass123!',
    phone: '+1234567890',
  },

  longEmail: {
    name: 'Long Email User',
    email: 'verylongemailaddressforexample123456@example.com',
    password: 'ValidPass123!',
    phone: '+1234567890',
  },

  inactiveUser: {
    id: '507f1f77bcf86cd799439011',
    name: 'Inactive User',
    email: 'inactive@example.com',
    password: '$2a$10$mock_hashed_password',
    phone: '+1234567890',
    isActive: false,
    role: 'user',
  },
};

// Test token fixtures
export const generateTestTokens = () => {
  const userId = '507f1f77bcf86cd799439012';
  const role = 'user';
  
  const accessToken = jwt.sign(
    { userId, role },
    config.jwt.secret as string,
    { expiresIn: config.jwt.accessExpiry }
  );
  
  const refreshToken = jwt.sign(
    { userId, role },
    config.jwt.refreshSecret as string,
    { expiresIn: config.jwt.refreshExpiry }
  );
  
  const expiredToken = jwt.sign(
    { userId, role },
    config.jwt.secret as string,
    { expiresIn: '-1h' } // Expired 1 hour ago
  );
  
  const invalidToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.invalid.signature';
  
  return {
    accessToken,
    refreshToken,
    expiredToken,
    invalidToken,
    userId,
  };
};

// Login credentials fixtures
export const loginCredentials = {
  validLogin: {
    email: 'john@example.com',
    password: 'SecurePass123!',
  },
  
  wrongPassword: {
    email: 'john@example.com',
    password: 'WrongPassword123!',
  },
  
  nonExistentUser: {
    email: 'nonexistent@example.com',
    password: 'AnyPassword123!',
  },
  
  missingEmail: {
    password: 'SecurePass123!',
  },
  
  missingPassword: {
    email: 'john@example.com',
  },
};

// Signup data fixtures
export const signupData = {
  validSignup: {
    name: 'Test User',
    email: 'testuser@example.com',
    password: 'TestPass123!',
    phone: '+1234567890',
    confirmPassword: 'TestPass123!',
  },
  
  mismatchedPasswords: {
    name: 'Test User',
    email: 'testuser@example.com',
    password: 'TestPass123!',
    phone: '+1234567890',
    confirmPassword: 'DifferentPass123!',
  },
  
  weakPassword: {
    name: 'Test User',
    email: 'testuser@example.com',
    password: 'weak',
    phone: '+1234567890',
    confirmPassword: 'weak',
  },

  noUppercase: {
    name: 'Test User',
    email: 'testuser@example.com',
    password: 'testpass123!',
    phone: '+1234567890',
    confirmPassword: 'testpass123!',
  },

  noSpecialChar: {
    name: 'Test User',
    email: 'testuser@example.com',
    password: 'TestPass123',
    phone: '+1234567890',
    confirmPassword: 'TestPass123',
  },
};

// Profile update data fixtures
export const profileUpdates = {
  validUpdate: {
    name: 'Updated Name',
    phone: '+9876543210',
    gender: 'Female',
    age: 35,
  },
  
  partialUpdate: {
    name: 'Only Name Updated',
  },
  
  invalidGender: {
    gender: 'InvalidGender',
  },
  
  invalidAge: {
    age: 17, // Below minimum
  },
  
  maxAge: {
    age: 120, // Valid max
  },
  
  overAge: {
    age: 121, // Above max
  },
};

// Error response fixtures
export const errorResponses = {
  validationError400: {
    statusCode: 400,
    status: 'fail',
    message: 'Validation error',
  },
  
  unauthorized401: {
    statusCode: 401,
    status: 'fail',
    message: 'Unauthorized',
  },
  
  forbidden403: {
    statusCode: 403,
    status: 'fail',
    message: 'Forbidden',
  },
  
  notFound404: {
    statusCode: 404,
    status: 'fail',
    message: 'Not found',
  },
  
  conflict409: {
    statusCode: 409,
    status: 'fail',
    message: 'Conflict',
  },
};
