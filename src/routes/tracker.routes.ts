import { Router, RequestHandler } from 'express';
import { authMiddleware } from '../middlewares/auth.middleware';
import { validateRequest } from '../middlewares/validate.middleware';
import { logWaterSchema, logSleepSchema, logStepsSchema, logVitalsSchema, logGlucoseSchema, logInsulinSchema, logMeasurementSchema } from '../schemas/tracker.schema';
import * as trackerController from '../controllers/tracker.controller';
import * as medicalController from '../controllers/medical.controller';

const router = Router();

const h = (fn: any): RequestHandler => fn;

router.use(h(authMiddleware));

router.post('/water', h(validateRequest(logWaterSchema)), h(trackerController.logWater));
router.get('/water', h(trackerController.getWaterLogs));

router.post('/sleep', h(validateRequest(logSleepSchema)), h(trackerController.logSleep));
router.get('/sleep', h(trackerController.getSleepLogs));

router.post('/steps', h(validateRequest(logStepsSchema)), h(trackerController.logSteps));
router.get('/steps', h(trackerController.getStepLogs));

router.post('/vitals', h(validateRequest(logVitalsSchema)), h(medicalController.logVitals));
router.get('/vitals', h(medicalController.getVitals));
router.delete('/vitals/:id', h(medicalController.deleteVitals));

router.post('/glucose', h(validateRequest(logGlucoseSchema)), h(medicalController.logGlucose));
router.get('/glucose', h(medicalController.getGlucose));
router.delete('/glucose/:id', h(medicalController.deleteGlucose));

router.post('/insulin', h(validateRequest(logInsulinSchema)), h(medicalController.logInsulin));
router.get('/insulin', h(medicalController.getInsulin));
router.delete('/insulin/:id', h(medicalController.deleteInsulin));

router.post('/measurements', h(validateRequest(logMeasurementSchema)), h(medicalController.logMeasurement));
router.get('/measurements', h(medicalController.getMeasurements));
router.delete('/measurements/:id', h(medicalController.deleteMeasurement));

export default router;
