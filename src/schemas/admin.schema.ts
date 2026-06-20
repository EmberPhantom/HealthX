import { z } from 'zod';

// Available slot time schema
const availableSlotSchema = z.object({
  day: z.string(),
  times: z.array(z.string()),
});

// Doctor validation schemas
export const createDoctorSchema = z.object({
  name: z.string({ required_error: 'Name is required' }).min(1),
  specialty: z.string({ required_error: 'Specialty is required' }).min(1),
  qualification: z.string({ required_error: 'Qualification is required' }).min(1),
  experience: z.number({ required_error: 'Experience is required' }).min(0),
  consultationFee: z.number({ required_error: 'Consultation fee is required' }).min(0),
  clinicName: z.string({ required_error: 'Clinic name is required' }).min(1),
  address: z.string({ required_error: 'Address is required' }).min(1),
  city: z.string({ required_error: 'City is required' }).min(1),
  languages: z.array(z.string()).optional().default([]),
  availableSlots: z.array(availableSlotSchema).optional().default([]),
  isActive: z.boolean().optional().default(true),
});

export const updateDoctorSchema = createDoctorSchema.partial();

// Menu Item validation schemas
export const createMenuItemSchema = z.object({
  name: z.string({ required_error: 'Name is required' }).min(1),
  description: z.string({ required_error: 'Description is required' }).min(1),
  price: z.number({ required_error: 'Price is required' }).min(0),
  calories: z.number({ required_error: 'Calories is required' }).min(0),
  imageUrl: z.string().optional().default(''),
  emoji: z.string().optional().default('🥗'),
  category: z.string({ required_error: 'Category is required' }).min(1),
  type: z.enum(['Regular', 'ReadyToEat']).optional().default('Regular'),
  tags: z.array(z.string()).optional().default([]),
  isVeg: z.boolean().optional().default(true),
});

export const updateMenuItemSchema = createMenuItemSchema.partial();

// Category validation schemas
export const createCategorySchema = z.object({
  name: z.string({ required_error: 'Category name is required' }).min(1),
  emoji: z.string().optional().default('🥗'),
});

export const updateCategorySchema = createCategorySchema.partial();

// Banner validation schemas
export const createBannerSchema = z.object({
  title: z.string({ required_error: 'Title is required' }).min(1),
  subtitle: z.string({ required_error: 'Subtitle is required' }).min(1),
  chipLabel: z.string({ required_error: 'Chip label is required' }).min(1),
  imagePath: z.string().optional().default(''),
});

export const updateBannerSchema = createBannerSchema.partial();

// User Admin updates validation schemas
export const updateUserRoleSchema = z.object({
  role: z.enum(['user', 'admin', 'provider'], { required_error: 'Role must be user, admin, or provider' }),
});

export const updateUserStatusSchema = z.object({
  isActive: z.boolean({ required_error: 'isActive boolean is required' }),
});
