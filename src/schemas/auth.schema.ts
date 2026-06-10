import { z } from 'zod';

// ─── Signup ─────────────────────────────────────────────────────────────────
// confirmPassword removed (UX-only concern for the client)
// phone made optional so Google OAuth users and bare-minimum signups work
export const signupSchema = z
  .object({
    name: z
      .string()
      .trim()
      .min(2, 'Name must be at least 2 characters')
      .max(100, 'Name must be less than 100 characters'),
    email: z
      .string()
      .email('Invalid email address')
      .toLowerCase(),
    password: z
      .string()
      .min(8, 'Password must be at least 8 characters')
      .regex(
        /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/,
        'Password must contain uppercase, lowercase, number and special character'
      ),
    phone: z
      .string()
      .regex(/^[+]?[0-9a-zA-Z\s().-]{3,25}$/, 'Invalid phone number')
      .optional(),
    confirmPassword: z.string().optional(),
  })
  .refine(
    (data) => {
      if (data.confirmPassword && data.password !== data.confirmPassword) {
        return false;
      }
      return true;
    },
    {
      message: 'Passwords do not match',
      path: ['confirmPassword'],
    }
  );

export type SignupInput = z.infer<typeof signupSchema>;

// ─── Login ───────────────────────────────────────────────────────────────────
export const loginSchema = z.object({
  email: z
    .string()
    .email('Invalid email address')
    .toLowerCase(),
  password: z
    .string()
    .min(1, 'Password is required'),
});

export type LoginInput = z.infer<typeof loginSchema>;

// ─── Google OAuth ─────────────────────────────────────────────────────────────
// Frontend sends { idToken: "..." } — align field name to idToken
export const googleAuthSchema = z.object({
  idToken: z
    .string()
    .min(1, 'Google ID token is required'),
});

export type GoogleAuthInput = z.infer<typeof googleAuthSchema>;

// ─── Refresh Token ────────────────────────────────────────────────────────────
export const refreshTokenSchema = z.object({
  refreshToken: z
    .string()
    .min(1, 'Refresh token is required'),
});

export type RefreshTokenInput = z.infer<typeof refreshTokenSchema>;

// ─── Update Profile ───────────────────────────────────────────────────────────
export const updateProfileSchema = z.object({
  name: z
    .string()
    .min(2, 'Name must be at least 2 characters')
    .max(100, 'Name must be less than 100 characters')
    .optional(),
  phone: z
    .string()
    .regex(/^[+]?[0-9a-zA-Z\s().-]{3,25}$/, 'Invalid phone number')
    .optional(),
  gender: z
    .enum(['Male', 'Female', 'Others'])
    .optional(),
  age: z
    .number()
    .min(18, 'Age must be at least 18')
    .max(120, 'Invalid age')
    .optional(),
  avatarUrl: z
    .string()
    .optional(),
});

export type UpdateProfileInput = z.infer<typeof updateProfileSchema>;

// ─── Forgot Password ─────────────────────────────────────────────────────────
export const forgotPasswordSchema = z.object({
  email: z
    .string()
    .email('Invalid email address')
    .toLowerCase(),
});

export type ForgotPasswordInput = z.infer<typeof forgotPasswordSchema>;

// ─── Reset Password ──────────────────────────────────────────────────────────
export const resetPasswordSchema = z.object({
  token: z.string().min(1, 'Reset token is required'),
  password: z
    .string()
    .min(8, 'Password must be at least 8 characters')
    .regex(
      /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/,
      'Password must contain uppercase, lowercase, number and special character'
    ),
});

export type ResetPasswordInput = z.infer<typeof resetPasswordSchema>;
