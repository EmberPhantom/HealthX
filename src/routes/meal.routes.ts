import express, { Router } from 'express';
import { authMiddleware } from '../middlewares/auth.middleware';
import * as mealController from '../controllers/meal.controller';
import { uploadImage, handleMulterError } from '../middlewares/upload.middleware';

const router: Router = express.Router();

router.use(authMiddleware as any);

router.post('/identify', mealController.identifyMeal as any);
router.post(
  '/identify-image',
  uploadImage as any,
  handleMulterError as any,
  mealController.identifyFromImage as any
);
router.post('/log', mealController.logMeal as any);
router.get('/', mealController.getMeals as any);
router.delete('/:id', mealController.deleteMeal as any);

export default router;
