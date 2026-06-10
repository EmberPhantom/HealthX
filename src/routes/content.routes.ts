import { Router, RequestHandler } from 'express';
import { authMiddleware } from '../middlewares/auth.middleware';
import * as contentController from '../controllers/content.controller';

const router = Router();

const h = (fn: any): RequestHandler => fn;

router.get('/categories', h(authMiddleware), h(contentController.getCategories));
router.get('/banners', h(authMiddleware), h(contentController.getBanners));
router.get('/meal-plans', h(authMiddleware), h(contentController.getMealPlans));
router.get('/menu-items', h(authMiddleware), h(contentController.getMenuItems));

export default router;
