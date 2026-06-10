import { Router, RequestHandler } from 'express';
import * as securityController from '../controllers/security.controller';
import { authMiddleware, roleMiddleware } from '../middlewares/auth.middleware';
import { generateCSRFToken } from '../middlewares/csrf.middleware';
import { validateRequest } from '../middlewares/validate.middleware';
import { z } from 'zod';

const router = Router();

const h = (fn: any): RequestHandler => fn;

const clearFailedAttemptsSchema = z.object({
  email: z.string().email('Invalid email address'),
});

router.get(
  '/csrf-token',
  h(generateCSRFToken),
  h(securityController.getCSRFToken)
);

router.get(
  '/login-history',
  h(authMiddleware),
  h(securityController.getLoginHistory)
);

router.get(
  '/suspicious-activity',
  h(authMiddleware),
  h(roleMiddleware(['admin'])),
  h(securityController.getSuspiciousActivity)
);

router.post(
  '/clear-failed-attempts',
  h(authMiddleware),
  h(roleMiddleware(['admin'])),
  h(validateRequest(clearFailedAttemptsSchema)),
  h(securityController.clearFailedAttempts)
);

router.get(
  '/audit-logs',
  h(authMiddleware),
  h(roleMiddleware(['admin'])),
  h(securityController.getAuditLogs)
);

export default router;
