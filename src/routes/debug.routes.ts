import { Router, RequestHandler } from 'express';
import * as debugController from '../controllers/debug.controller';
import { authMiddleware, roleMiddleware } from '../middlewares/auth.middleware';

const router = Router();

const h = (fn: any): RequestHandler => fn;

router.get('/db-info', h(authMiddleware), h(roleMiddleware(['admin'])), h(debugController.getDbInfo));

export default router;
