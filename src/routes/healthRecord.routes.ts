import { Router } from 'express';
import * as healthRecordController from '../controllers/healthRecord.controller';
import { authMiddleware } from '../middlewares/auth.middleware';
import { uploadHealthRecord, handleMulterError } from '../middlewares/upload.middleware';

const router = Router();

router.use(authMiddleware as any);

router.get('/', healthRecordController.getHealthRecords as any);
router.post(
  '/',
  uploadHealthRecord as any,
  handleMulterError as any,
  healthRecordController.createHealthRecord as any
);
router.delete('/:id', healthRecordController.deleteHealthRecord as any);

export default router;
