import { Router, RequestHandler } from 'express';
import { authMiddleware } from '../middlewares/auth.middleware';
import * as doctorController from '../controllers/doctor.controller';

const router = Router();

const h = (fn: any): RequestHandler => fn;

router.get('/', h(doctorController.getDoctors));
router.get('/:id', h(doctorController.getDoctor));
router.get('/:id/slots', h(authMiddleware), h(doctorController.getDoctorSlots));

export default router;
