import { Router } from 'express';
import { getMessages, sendMessage } from '../controllers/chat.controller';
import { authMiddleware } from '../middlewares/auth.middleware';

const router = Router();

// All chat routes require authentication
router.use(authMiddleware as any);

router.route('/:appointmentId/messages')
  .get(getMessages as any)
  .post(sendMessage as any);

export default router;
