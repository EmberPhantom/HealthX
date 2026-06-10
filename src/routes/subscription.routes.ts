import { Router, RequestHandler } from 'express';
import * as subscriptionController from '../controllers/subscription.controller';
import { authMiddleware } from '../middlewares/auth.middleware';

const router = Router();

const h = (fn: any): RequestHandler => fn;

router.use(h(authMiddleware));

router.post('/subscribe', h(subscriptionController.subscribeToPlan));
router.post('/pause/:id', h(subscriptionController.pauseSubscription));
router.post('/cancel/:id', h(subscriptionController.cancelSubscription));
router.get('/me', h(subscriptionController.getUserSubscriptions));

export default router;
