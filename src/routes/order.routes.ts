import express, { Router } from 'express';
import { authMiddleware } from '../middlewares/auth.middleware';
import * as orderController from '../controllers/order.controller';

const router: Router = express.Router();

router.use(authMiddleware as any);

router.post('/', orderController.placeOrder as any);
router.get('/', orderController.getOrders as any);
router.get('/:id', orderController.getOrder as any);
router.post('/:id/cancel', orderController.cancelOrder as any);
router.get('/:id/status', orderController.getOrderStatus as any);

export default router;
