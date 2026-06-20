import { z } from 'zod';

export const subscribeSchema = z.object({
  planId: z.string(),
  billingPeriod: z.enum(['weekly', 'monthly']).optional(),
});

export type SubscribeInput = z.infer<typeof subscribeSchema>;
