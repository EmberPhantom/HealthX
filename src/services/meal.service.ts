import fs from 'fs';
import path from 'path';
import MealLog, { IMealLog } from '../models/MealLog';
import { AppError } from '../utils/AppError';
import logger from '../utils/logger';
import geminiService from './gemini.service';

export class MealService {
  /**
   * AI identification of food from image or text
   */
  async identifyMeal(input: { text?: string; imageUrl?: string }) {
    if (geminiService.isAvailable()) {
      logger.info('Performing AI meal identification via Gemini API...');
      let base64Image: string | undefined;
      let mimeType: string | undefined;

      if (input.imageUrl) {
        try {
          const relativePath = input.imageUrl.replace(/^\//, ''); // strip leading slash
          const fullPath = path.join(process.cwd(), relativePath);
          if (fs.existsSync(fullPath)) {
            const buffer = fs.readFileSync(fullPath);
            base64Image = buffer.toString('base64');
            const ext = path.extname(fullPath).toLowerCase();
            mimeType = ext === '.png' ? 'image/png' : ext === '.webp' ? 'image/webp' : 'image/jpeg';
          }
        } catch (err) {
          logger.error('Error reading image for Gemini identification:', err);
        }
      }

      try {
        const result = await geminiService.identifyMeal({
          text: input.text,
          base64Image,
          mimeType,
        });
        return result;
      } catch (err) {
        logger.error('Gemini identification failed, falling back to mock logic:', err);
      }
    }

    logger.info('Simulating AI meal identification (Mock mode)...');

    // Simulate processing delay
    await new Promise(resolve => setTimeout(resolve, 1000));

    const textInput = input.text?.toLowerCase() || '';
    let foodName = 'Healthy Salad Bowl';
    let calories = 340;
    let protein = 12;
    let fat = 8;
    let carbs = 54;
    let ingredients = ['Romaine lettuce', 'Cherry tomatoes', 'Cucumber slices', 'Olive oil dressing', 'Quinoa'];
    let healthScore = 9;
    let vitamins = ['Vitamin A', 'Vitamin C', 'Vitamin K'];
    let servingSize = '1 bowl (350g)';
    let confidence = 0.95;
    let healthPoints = [
      { text: 'Excellent source of antioxidants', ok: true },
      { text: 'Low in saturated fat and sodium', ok: true },
      { text: 'Rich in vitamin K and dietary fiber', ok: true }
    ];

    if (textInput.includes('pizza')) {
      foodName = 'Cheese & Tomato Pizza Slice';
      calories = 285;
      protein = 12;
      fat = 10;
      carbs = 36;
      ingredients = ['Wheat flour crust', 'Mozzarella cheese', 'Tomato pizza sauce', 'Oregano & herbs'];
      healthScore = 5;
      vitamins = ['Calcium', 'Vitamin A'];
      servingSize = '1 slice (100g)';
      confidence = 0.98;
      healthPoints = [
        { text: 'Good source of calcium and protein', ok: true },
        { text: 'High in refined carbohydrates', ok: false },
        { text: 'Contains moderate sodium', ok: false }
      ];
    } else if (textInput.includes('chicken') || textInput.includes('meat')) {
      foodName = 'Grilled Chicken Breast';
      calories = 198;
      protein = 37;
      fat = 4;
      carbs = 0;
      ingredients = ['Skinless chicken breast', 'Olive oil', 'Black pepper', 'Sea salt', 'Garlic powder'];
      healthScore = 9;
      vitamins = ['Vitamin B6', 'Niacin', 'Selenium', 'Phosphorus'];
      servingSize = '1 piece (120g)';
      confidence = 0.92;
      healthPoints = [
        { text: 'Very high in lean protein', ok: true },
        { text: 'Very low in carbohydrates', ok: true },
        { text: 'Contains essential B vitamins', ok: true }
      ];
    } else if (textInput.includes('snack') || textInput.includes('mixed')) {
      foodName = 'Mixed snack platter';
      calories = 1261;
      protein = 32;
      fat = 47;
      carbs = 177;
      ingredients = [
        'Sweet corn kernels',
        'Sliced carrots',
        'Sliced cucumber',
        'Papaya chunks',
        'Black grapes',
        'Assorted soaked legumes',
        'Mixed nuts and dates'
      ];
      healthScore = 8;
      healthPoints = [
        { text: 'Low in sodium and no added sugars', ok: true },
        { text: 'Contains healthy unsaturated fats from nuts', ok: true },
        { text: 'Rich in vitamins A and C', ok: true },
        { text: 'High in dietary fiber', ok: true },
        { text: 'Natural sugar content is relatively high', ok: false }
      ];
      vitamins = ['Vitamin A', 'Vitamin C', 'Iron'];
      servingSize = '1 platter (400g)';
      confidence = 0.87;
    }

    return {
      foodName,
      name: foodName, // for backward compatibility
      calories,
      protein,
      fat,
      carbs,
      ingredients,
      healthScore,
      vitamins,
      servingSize,
      confidence,
      healthPoints
    };
  }

  /**
   * Log a meal to the database
   */
  async logMeal(userId: string, mealData: any): Promise<IMealLog> {
    try {
      const mealLog = await MealLog.create({
        userId,
        ...mealData
      });

      logger.info(`Meal logged for user ${userId}: ${mealData.foodName}`);
      return mealLog;
    } catch (error) {
      logger.error('Log meal error:', error);
      throw new AppError('Failed to log meal', 500);
    }
  }

  /**
   * Get meal logs for a user on a specific date
   */
  async getMealsByDate(userId: string, date: Date): Promise<IMealLog[]> {
    const startOfDay = new Date(date);
    startOfDay.setHours(0, 0, 0, 0);

    const endOfDay = new Date(date);
    endOfDay.setHours(23, 59, 59, 999);

    return await MealLog.find({
      userId,
      loggedAt: { $gte: startOfDay, $lte: endOfDay }
    }).sort({ loggedAt: -1 });
  }

  /**
   * Delete a meal log
   */
  async deleteMealLog(userId: string, mealId: string): Promise<IMealLog | null> {
    try {
      const meal = await MealLog.findOne({ _id: mealId, userId });
      if (!meal) return null;
      await meal.deleteOne();
      return meal;
    } catch (error) {
      logger.error('Delete meal error:', error);
      throw new AppError('Failed to delete meal log', 500);
    }
  }
}

export const mealService = new MealService();
