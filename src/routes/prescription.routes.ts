import { Router } from 'express';
import { getPrescription, createPrescription } from '../controllers/prescription.controller';
import { authMiddleware } from '../middlewares/auth.middleware';

const router = Router();

// All prescription routes require authentication
router.use(authMiddleware as any);

router.post('/', createPrescription as any);
router.get('/:appointmentId', getPrescription as any);

export default router;
