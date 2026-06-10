import express, { Router } from 'express';
import { authMiddleware } from '../middlewares/auth.middleware';
import * as addressController from '../controllers/address.controller';

const router: Router = express.Router();

router.use(authMiddleware as any);

router.get('/', addressController.getAddresses as any);
router.post('/', addressController.createAddress as any);
router.put('/:id', addressController.updateAddress as any);
router.delete('/:id', addressController.deleteAddress as any);
router.patch('/:id/default', addressController.setDefaultAddress as any);

export default router;
