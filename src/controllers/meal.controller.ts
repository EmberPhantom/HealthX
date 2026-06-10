import { Response } from 'express';
import { mealService } from '../services/meal.service';
import { catchAsync } from '../utils/catchAsync';
import { AuthRequest } from '../middlewares/auth.middleware';
import { AppError } from '../utils/AppError';

/**
 * POST /meals/identify
 * Identify meal from image or text
 */
export const identifyMeal = catchAsync(async (req: AuthRequest, res: Response) => {
  const { text, imageUrl } = req.body;

  const result = await mealService.identifyMeal({ text, imageUrl });

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: result,
  });
});

/**
 * POST /meals/log
 * Log a meal
 */
export const logMeal = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const mealLog = await mealService.logMeal(req.user.userId, req.body);

  res.status(201).json({
    statusCode: 201,
    status: 'success',
    message: 'Meal logged successfully',
    data: mealLog,
  });
});

/**
 * GET /meals
 * Get user's meal logs for a date
 */
export const getMeals = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const date = req.query.date ? new Date(req.query.date as string) : new Date();
  const meals = await mealService.getMealsByDate(req.user.userId, date);

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: meals,
  });
});

/**
 * DELETE /meals/:id
 * Delete a meal log
 */
export const deleteMeal = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const mealId = req.params.id;
  const deleted = await mealService.deleteMealLog(req.user.userId, mealId);

  if (!deleted) {
    throw new AppError('Meal log not found', 404);
  }

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    message: 'Meal log deleted successfully',
  });
});

/**
 * POST /meals/identify-image
 * Upload image and identify meal
 */
export const identifyFromImage = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.file) {
    throw new AppError('No image uploaded', 400);
  }

  const { default: storageService } = await import('../services/storage.service');
  const imageUrl = await storageService.saveImage(req.file, 'meals');

  const result = await mealService.identifyMeal({ imageUrl });

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: result,
  });
});
