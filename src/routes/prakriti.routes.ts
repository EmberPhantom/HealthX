import { Router } from 'express';
import * as prakritiController from '../controllers/prakriti.controller';
import { authMiddleware } from '../middlewares/auth.middleware';

const router = Router();

router.use(authMiddleware as any);

router.get('/questions', prakritiController.getQuestions as any);
router.post('/submit', prakritiController.submitAssessment as any);

export default router;
