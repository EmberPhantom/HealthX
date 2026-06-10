import { Router, RequestHandler } from 'express';
import { authMiddleware } from '../middlewares/auth.middleware';
import * as trackerController from '../controllers/tracker.controller';
import * as medicalController from '../controllers/medical.controller';

const router = Router();

const h = (fn: any): RequestHandler => fn;

router.use(h(authMiddleware));

router.post('/water', h(trackerController.logWater));
router.get('/water', h(trackerController.getWaterLogs));

router.post('/sleep', h(trackerController.logSleep));
router.get('/sleep', h(trackerController.getSleepLogs));

router.post('/steps', h(trackerController.logSteps));
router.get('/steps', h(trackerController.getStepLogs));

router.post('/vitals', h(medicalController.logVitals));
router.get('/vitals', h(medicalController.getVitals));
router.delete('/vitals/:id', h(medicalController.deleteVitals));

router.post('/glucose', h(medicalController.logGlucose));
router.get('/glucose', h(medicalController.getGlucose));
router.delete('/glucose/:id', h(medicalController.deleteGlucose));

router.post('/insulin', h(medicalController.logInsulin));
router.get('/insulin', h(medicalController.getInsulin));
router.delete('/insulin/:id', h(medicalController.deleteInsulin));

router.post('/measurements', h(medicalController.logMeasurement));
router.get('/measurements', h(medicalController.getMeasurements));
router.delete('/measurements/:id', h(medicalController.deleteMeasurement));

export default router;
