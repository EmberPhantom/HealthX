import express, { Router } from 'express';
import { authMiddleware } from '../middlewares/auth.middleware';
import * as contentController from '../controllers/content.controller';

const router: Router = express.Router();

router.get('/categories', authMiddleware as any, contentController.getCategories as any);
router.get('/banners', authMiddleware as any, contentController.getBanners as any);
router.get('/meal-plans', authMiddleware as any, contentController.getMealPlans as any);
router.get('/menu-items', authMiddleware as any, contentController.getMenuItems as any);

export default router;
