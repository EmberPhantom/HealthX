import express, { Router } from 'express';
import { authMiddleware } from '../middlewares/auth.middleware';
import * as trackerController from '../controllers/tracker.controller';
import * as medicalController from '../controllers/medical.controller';

const router: Router = express.Router();

router.use(authMiddleware as any);

router.post('/water', trackerController.logWater as any);
router.get('/water', trackerController.getWaterLogs as any);

router.post('/sleep', trackerController.logSleep as any);
router.get('/sleep', trackerController.getSleepLogs as any);

router.post('/steps', trackerController.logSteps as any);
router.get('/steps', trackerController.getStepLogs as any);

// Medical Trackers
router.post('/vitals', medicalController.logVitals as any);
router.get('/vitals', medicalController.getVitals as any);
router.delete('/vitals/:id', medicalController.deleteVitals as any);

router.post('/glucose', medicalController.logGlucose as any);
router.get('/glucose', medicalController.getGlucose as any);
router.delete('/glucose/:id', medicalController.deleteGlucose as any);

router.post('/insulin', medicalController.logInsulin as any);
router.get('/insulin', medicalController.getInsulin as any);
router.delete('/insulin/:id', medicalController.deleteInsulin as any);

router.post('/measurements', medicalController.logMeasurement as any);
router.get('/measurements', medicalController.getMeasurements as any);
router.delete('/measurements/:id', medicalController.deleteMeasurement as any);

export default router;
