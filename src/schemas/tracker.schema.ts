import { z } from 'zod';

export const logWaterSchema = z.object({
  amount: z.number().min(1, 'Amount must be at least 1').max(10000, 'Amount must be at most 10000'),
  date: z.string().optional(),
});

export const logSleepSchema = z.object({
  bedtime: z.string(),
  wakeTime: z.string(),
  dateKey: z.string(),
});

export const logStepsSchema = z.object({
  steps: z.number().min(0, 'Steps cannot be negative'),
  dateKey: z.string(),
});

export const logVitalsSchema = z.object({
  date: z.string(),
  time: z.string(),
  bp: z.string().optional(),
  pulse: z.number().min(20, 'Pulse must be at least 20').max(300, 'Pulse must be at most 300').optional(),
  temperature: z.number().optional(),
  weight: z.number().optional(),
  spo2: z.number().min(50, 'SpO2 must be at least 50').max(100, 'SpO2 must be at most 100').optional(),
  exerciseMins: z.number().min(0, 'Exercise minutes cannot be negative').optional(),
});

export const logGlucoseSchema = z.object({
  level: z.number().min(0, 'Glucose level must be at least 0').max(600, 'Glucose level must be at most 600'),
  readingType: z.enum(['fasting', 'post_meal', 'random', 'bedtime']),
  note: z.string().optional(),
  loggedAt: z.string().optional(),
});

export const logInsulinSchema = z.object({
  dose: z.number().min(0, 'Dose must be at least 0').max(500, 'Dose must be at most 500'),
  insulinType: z.string(),
  injectionSite: z.string().optional(),
  mealContext: z.enum(['before_meal', 'after_meal', 'bedtime']).optional(),
  note: z.string().optional(),
  loggedAt: z.string().optional(),
});

export const logMeasurementSchema = z.object({
  weight: z.number().optional(),
  height: z.number().optional(),
  chest: z.number().optional(),
  waist: z.number().optional(),
  hips: z.number().optional(),
  bodyFatPercent: z.number().min(0, 'Body fat % must be at least 0').max(100, 'Body fat % must be at most 100').optional(),
  loggedAt: z.string().optional(),
});

export type LogWaterInput = z.infer<typeof logWaterSchema>;
export type LogSleepInput = z.infer<typeof logSleepSchema>;
export type LogStepsInput = z.infer<typeof logStepsSchema>;
export type LogVitalsInput = z.infer<typeof logVitalsSchema>;
export type LogGlucoseInput = z.infer<typeof logGlucoseSchema>;
export type LogInsulinInput = z.infer<typeof logInsulinSchema>;
export type LogMeasurementInput = z.infer<typeof logMeasurementSchema>;
