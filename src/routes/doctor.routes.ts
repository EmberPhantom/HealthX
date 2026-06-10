import { Router } from 'express';
import { authMiddleware } from '../middlewares/auth.middleware';
import * as doctorController from '../controllers/doctor.controller';

const router = Router();

// Doctor search/list is public, slots require auth
router.get('/', doctorController.getDoctors as any);
router.get('/:id', doctorController.getDoctor as any);
router.get('/:id/slots', authMiddleware as any, doctorController.getDoctorSlots as any);

export default router;
