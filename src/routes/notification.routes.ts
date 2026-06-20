import { Router, RequestHandler } from 'express';
import { authMiddleware } from '../middlewares/auth.middleware';
import * as notificationController from '../controllers/notification.controller';

const router = Router();

const h = (fn: any): RequestHandler => fn;

router.use(h(authMiddleware));

// ── Notification feed ─────────────────────────────────────────────────────────
router.get('/', h(notificationController.getNotifications));
router.get('/unread-count', h(notificationController.getUnreadCount));

// ── Mark read ─────────────────────────────────────────────────────────────────
router.patch('/read-all', h(notificationController.markAllRead));
router.patch('/:id/read', h(notificationController.markAsRead));

// ── Delete ────────────────────────────────────────────────────────────────────
router.delete('/:id', h(notificationController.deleteNotification));

// ── FCM device token management ───────────────────────────────────────────────
// Note: these endpoints live under /notifications/fcm-token for simplicity,
// though conceptually they belong to the user resource.
router.post('/fcm-token', h(notificationController.registerFcmToken));
router.delete('/fcm-token', h(notificationController.removeFcmToken));

export default router;
