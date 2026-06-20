import { z } from 'zod';

export const identifyMealSchema = z
  .object({
    text: z.string().optional(),
    imageUrl: z.string().optional(),
  })
  .refine((data) => data.text || data.imageUrl, {
    message: 'At least one of text or imageUrl is required',
    path: ['text'],
  });

export const logMealSchema = z.object({
  mealType: z.enum(['Breakfast', 'Lunch', 'Dinner', 'Snack']),
  foodName: z.string(),
  calories: z.number(),
  protein: z.number().optional(),
  fat: z.number().optional(),
  carbs: z.number().optional(),
  imageUrl: z.string().optional(),
  ingredients: z.array(z.string()).optional(),
});

export type IdentifyMealInput = z.infer<typeof identifyMealSchema>;
export type LogMealInput = z.infer<typeof logMealSchema>;
