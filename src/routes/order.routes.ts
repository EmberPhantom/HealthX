import { Router, RequestHandler } from 'express';
import { authMiddleware } from '../middlewares/auth.middleware';
import * as orderController from '../controllers/order.controller';

const router = Router();

const h = (fn: any): RequestHandler => fn;

router.use(h(authMiddleware));

router.post('/', h(orderController.placeOrder));
router.get('/', h(orderController.getOrders));
router.get('/:id', h(orderController.getOrder));
router.post('/:id/cancel', h(orderController.cancelOrder));
router.get('/:id/status', h(orderController.getOrderStatus));

export default router;
