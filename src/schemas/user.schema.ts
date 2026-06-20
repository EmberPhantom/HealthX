import { z } from 'zod';

export const updateSettingsSchema = z.object({
  dailyWaterGoalMl: z.number().min(500, 'Water goal must be at least 500 ml').max(10000, 'Water goal must be at most 10000 ml').optional(),
  dailyStepGoal: z.number().min(1000, 'Step goal must be at least 1000').max(50000, 'Step goal must be at most 50000').optional(),
  dailyCalorieGoal: z.number().min(500, 'Calorie goal must be at least 500 kcal').max(10000, 'Calorie goal must be at most 10000 kcal').optional(),
  dailyProteinGoalG: z.number().min(10, 'Protein goal must be at least 10g').max(500, 'Protein goal must be at most 500g').optional(),
  dailyCarbGoalG: z.number().min(10, 'Carb goal must be at least 10g').max(1000, 'Carb goal must be at most 1000g').optional(),
  dailyFatGoalG: z.number().min(10, 'Fat goal must be at least 10g').max(500, 'Fat goal must be at most 500g').optional(),
  reminderEnabled: z.boolean().optional(),
});

export const toggleFavoriteSchema = z.object({
  itemId: z.string(),
});

export const updateWellnessGoalsSchema = z.object({
  goals: z.array(z.string()).optional(),
});

export const setAppRatingSchema = z.object({
  rating: z.number().min(1, 'Rating must be at least 1').max(5, 'Rating must be at most 5'),
});

export const updatePointsSchema = z.object({
  points: z.number(),
});

export type UpdateSettingsInput = z.infer<typeof updateSettingsSchema>;
export type ToggleFavoriteInput = z.infer<typeof toggleFavoriteSchema>;
export type UpdateWellnessGoalsInput = z.infer<typeof updateWellnessGoalsSchema>;
export type SetAppRatingInput = z.infer<typeof setAppRatingSchema>;
export type UpdatePointsInput = z.infer<typeof updatePointsSchema>;
