import { Router } from 'express';
import * as subscriptionController from '../controllers/subscription.controller';
import { authMiddleware } from '../middlewares/auth.middleware';

const router = Router();

router.use(authMiddleware as any);

router.post('/subscribe', subscriptionController.subscribeToPlan as any);
router.post('/pause/:id', subscriptionController.pauseSubscription as any);
router.post('/cancel/:id', subscriptionController.cancelSubscription as any);
router.get('/me', subscriptionController.getUserSubscriptions as any);

export default router;
