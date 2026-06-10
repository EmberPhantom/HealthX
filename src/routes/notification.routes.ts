import express, { Router } from 'express';
import { authMiddleware } from '../middlewares/auth.middleware';
import * as notificationController from '../controllers/notification.controller';

const router: Router = express.Router();

router.use(authMiddleware as any);

router.get('/', notificationController.getNotifications as any);
router.patch('/:id/read', notificationController.markAsRead as any);
router.delete('/:id', notificationController.deleteNotification as any);

export default router;
