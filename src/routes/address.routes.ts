import { Router, RequestHandler } from 'express';
import { authMiddleware } from '../middlewares/auth.middleware';
import * as addressController from '../controllers/address.controller';

const router = Router();

const h = (fn: any): RequestHandler => fn;

router.use(h(authMiddleware));

router.get('/', h(addressController.getAddresses));
router.post('/', h(addressController.createAddress));
router.put('/:id', h(addressController.updateAddress));
router.delete('/:id', h(addressController.deleteAddress));
router.patch('/:id/default', h(addressController.setDefaultAddress));

export default router;
