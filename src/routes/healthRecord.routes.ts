import { Router, RequestHandler } from 'express';
import { validateRequest } from '../middlewares/validate.middleware';
import { createHealthRecordSchema } from '../schemas/healthRecord.schema';
import * as healthRecordController from '../controllers/healthRecord.controller';
import { authMiddleware } from '../middlewares/auth.middleware';
import { uploadHealthRecord, handleMulterError } from '../middlewares/upload.middleware';

const router = Router();

const h = (fn: any): RequestHandler => fn;

router.use(h(authMiddleware));

router.get('/', h(healthRecordController.getHealthRecords));
router.post(
  '/',
  h(uploadHealthRecord),
  h(handleMulterError),
  h(validateRequest(createHealthRecordSchema)),
  h(healthRecordController.createHealthRecord)
);
router.delete('/:id', h(healthRecordController.deleteHealthRecord));

export default router;
