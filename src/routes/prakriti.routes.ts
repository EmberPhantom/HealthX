import { Router, RequestHandler } from 'express';
import { validateRequest } from '../middlewares/validate.middleware';
import { submitAssessmentSchema } from '../schemas/prakriti.schema';
import * as prakritiController from '../controllers/prakriti.controller';
import { authMiddleware } from '../middlewares/auth.middleware';

const router = Router();

const h = (fn: any): RequestHandler => fn;

router.use(h(authMiddleware));

router.get('/questions', h(prakritiController.getQuestions));
router.post('/submit', h(validateRequest(submitAssessmentSchema)), h(prakritiController.submitAssessment));
router.get('/latest', h(prakritiController.getLatestAssessment));

export default router;
