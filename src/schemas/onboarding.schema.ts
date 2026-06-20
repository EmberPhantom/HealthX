import { z } from 'zod';

export const verifyEmailSchema = z.object({
  token: z.string().min(1, 'Verification token is required'),
});

export const resendVerificationSchema = z.object({});

export const completeOnboardingSchema = z.object({
  medicalHistory: z.string().optional(),
  allergies: z.union([z.string(), z.array(z.string())]).optional(),
  medications: z.union([z.string(), z.array(z.string())]).optional(),
  emergencyContactName: z.string().min(1, 'Emergency contact name is required').optional(),
  emergencyContactPhone: z.string().min(1, 'Emergency contact phone is required').optional(),
  insuranceProvider: z.string().optional(),
  insurancePolicyNo: z.string().optional(),
  height: z.number().min(50, 'Height must be at least 50 cm').max(300, 'Invalid height').optional(),
  weight: z.number().min(10, 'Weight must be at least 10 kg').max(500, 'Invalid weight').optional(),
  isDiabetesPatient: z.boolean().optional(),
  isBpPatient: z.boolean().optional(),
  wellnessGoals: z.array(z.string()).optional(),
  dominantDosha: z.enum(['Vata', 'Pitta', 'Kapha', 'Vata-Pitta', 'Pitta-Kapha', 'Vata-Kapha', 'Tridoshic']).optional(),
  activityLevel: z.number().min(0).max(4).optional(),
  gender: z.enum(['Male', 'Female', 'Others']).optional(),
  dateOfBirth: z.string().optional(),
  phone: z.string().regex(/^[+]?[0-9a-zA-Z\s().-]{3,25}$/, 'Invalid phone number').optional(),
  avatarUrl: z.string().optional(),
  age: z.number().min(18).max(120).optional(),
});
