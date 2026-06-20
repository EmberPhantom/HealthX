import { Router, RequestHandler } from 'express';
import { authMiddleware } from '../middlewares/auth.middleware';
import { validateRequest } from '../middlewares/validate.middleware';
import { identifyMealSchema, logMealSchema } from '../schemas/meal.schema';
import * as mealController from '../controllers/meal.controller';
import { uploadImage, handleMulterError } from '../middlewares/upload.middleware';

const router = Router();

const h = (fn: any): RequestHandler => fn;

router.use(h(authMiddleware));

router.post('/identify', h(validateRequest(identifyMealSchema)), h(mealController.identifyMeal));
router.post(
  '/identify-image',
  h(uploadImage),
  h(handleMulterError),
  h(mealController.identifyFromImage)
);
router.post('/log', h(validateRequest(logMealSchema)), h(mealController.logMeal));
router.get('/', h(mealController.getMeals));
router.delete('/:id', h(mealController.deleteMeal));

export default router;
