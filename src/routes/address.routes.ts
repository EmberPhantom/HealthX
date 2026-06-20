import { Router, RequestHandler } from 'express';
import { authMiddleware } from '../middlewares/auth.middleware';
import { validateRequest } from '../middlewares/validate.middleware';
import { createAddressSchema, updateAddressSchema } from '../schemas/address.schema';
import * as addressController from '../controllers/address.controller';

const router = Router();

const h = (fn: any): RequestHandler => fn;

router.use(h(authMiddleware));

router.get('/', h(addressController.getAddresses));
router.post('/', h(validateRequest(createAddressSchema)), h(addressController.createAddress));
router.put('/:id', h(validateRequest(updateAddressSchema)), h(addressController.updateAddress));
router.delete('/:id', h(addressController.deleteAddress));
router.patch('/:id/default', h(addressController.setDefaultAddress));

export default router;
