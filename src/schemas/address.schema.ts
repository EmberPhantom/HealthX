import { z } from 'zod';

const indianPincodeRegex = /^[1-9][0-9]{5}$/;

export const createAddressSchema = z.object({
  label: z.string().min(1, 'Label is required'),
  street: z.string().min(1, 'Street is required'),
  area: z.string().min(1, 'Area is required'),
  city: z.string().min(1, 'City is required'),
  pincode: z.string().regex(indianPincodeRegex, 'Invalid Indian pincode'),
  isDefault: z.boolean().optional(),
});

export const updateAddressSchema = z.object({
  label: z.string().min(1, 'Label is required').optional(),
  street: z.string().min(1, 'Street is required').optional(),
  area: z.string().min(1, 'Area is required').optional(),
  city: z.string().min(1, 'City is required').optional(),
  pincode: z.string().regex(indianPincodeRegex, 'Invalid Indian pincode').optional(),
  isDefault: z.boolean().optional(),
});

export type CreateAddressInput = z.infer<typeof createAddressSchema>;
export type UpdateAddressInput = z.infer<typeof updateAddressSchema>;
