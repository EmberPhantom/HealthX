import { Router, RequestHandler } from 'express';
import * as prakritiController from '../controllers/prakriti.controller';
import { authMiddleware } from '../middlewares/auth.middleware';

const router = Router();

const h = (fn: any): RequestHandler => fn;

router.use(h(authMiddleware));

router.get('/questions', h(prakritiController.getQuestions));
router.post('/submit', h(prakritiController.submitAssessment));

export default router;
