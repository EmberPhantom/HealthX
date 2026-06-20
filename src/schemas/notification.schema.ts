import { z } from 'zod';

export const markAsReadSchema = z.object({});

export type MarkAsReadInput = z.infer<typeof markAsReadSchema>;
