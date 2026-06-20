import { z } from 'zod';

export const createHealthRecordSchema = z.object({
  name: z.string().min(1, 'Name is required'),
  type: z.enum(['labTests', 'prescription', 'scans', 'other']),
  date: z.string(),
  specialist: z.string().optional(),
});

export type CreateHealthRecordInput = z.infer<typeof createHealthRecordSchema>;
