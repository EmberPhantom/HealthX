import { z } from 'zod';

const orderItemSchema = z.object({
  menuItemId: z.string(),
  name: z.string(),
  quantity: z.number().min(1, 'Quantity must be at least 1'),
  price: z.number().min(0, 'Price cannot be negative'),
});

export const placeOrderSchema = z.object({
  items: z.array(orderItemSchema).min(1, 'At least one item is required'),
  addressId: z.string(),
  paymentMethod: z.string(),
});

export const cancelOrderSchema = z.object({
  cancelReason: z.string().optional(),
});

export type PlaceOrderInput = z.infer<typeof placeOrderSchema>;
export type CancelOrderInput = z.infer<typeof cancelOrderSchema>;
