import { Router } from 'express';
import { authMiddleware } from '../middlewares/auth.middleware';
import * as appointmentController from '../controllers/appointment.controller';

const router = Router();

router.use(authMiddleware as any);

router.post('/', appointmentController.bookAppointment as any);
router.get('/', appointmentController.getAppointments as any);
router.get('/:id', appointmentController.getAppointment as any);
router.delete('/:id', appointmentController.cancelAppointment as any); // Cancel appointment

export default router;
