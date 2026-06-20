import { Router, RequestHandler } from 'express';
import { authMiddleware } from '../middlewares/auth.middleware';
import { validateRequest } from '../middlewares/validate.middleware';
import { placeOrderSchema, cancelOrderSchema } from '../schemas/order.schema';
import * as orderController from '../controllers/order.controller';

const router = Router();

const h = (fn: any): RequestHandler => fn;

router.use(h(authMiddleware));

router.post('/', h(validateRequest(placeOrderSchema)), h(orderController.placeOrder));
router.get('/', h(orderController.getOrders));
router.get('/:id', h(orderController.getOrder));
router.post('/:id/cancel', h(validateRequest(cancelOrderSchema)), h(orderController.cancelOrder));
router.get('/:id/status', h(orderController.getOrderStatus));

export default router;
