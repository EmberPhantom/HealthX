import { Router, RequestHandler } from 'express';
import { authMiddleware } from '../middlewares/auth.middleware';
import { validateRequest } from '../middlewares/validate.middleware';
import { bookAppointmentSchema } from '../schemas/appointment.schema';
import * as appointmentController from '../controllers/appointment.controller';

const router = Router();

const h = (fn: any): RequestHandler => fn;

router.use(h(authMiddleware));

router.post('/', h(validateRequest(bookAppointmentSchema)), h(appointmentController.bookAppointment));
router.get('/', h(appointmentController.getAppointments));
router.get('/:id', h(appointmentController.getAppointment));
router.delete('/:id', h(appointmentController.cancelAppointment));

export default router;
