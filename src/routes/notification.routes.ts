import { Router, RequestHandler } from 'express';
import { authMiddleware } from '../middlewares/auth.middleware';
import * as notificationController from '../controllers/notification.controller';

const router = Router();

const h = (fn: any): RequestHandler => fn;

router.use(h(authMiddleware));

router.get('/', h(notificationController.getNotifications));
router.patch('/:id/read', h(notificationController.markAsRead));
router.delete('/:id', h(notificationController.deleteNotification));

export default router;
