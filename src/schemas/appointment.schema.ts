import { z } from 'zod';

export const bookAppointmentSchema = z.object({
  doctorId: z.string(),
  appointmentDate: z.string(),
  timeSlot: z.string(),
  type: z.enum(['in-person', 'video']).optional().default('in-person'),
  symptoms: z.string().optional(),
  notes: z.string().optional(),
});

export type BookAppointmentInput = z.infer<typeof bookAppointmentSchema>;
