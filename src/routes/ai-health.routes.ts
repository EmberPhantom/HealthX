import { Router, RequestHandler } from 'express';
import { authMiddleware } from '../middlewares/auth.middleware';
import * as aiHealthController from '../controllers/ai-health.controller';

const router = Router();

const h = (fn: any): RequestHandler => fn;

// All routes require authentication
router.use(h(authMiddleware));

/**
 * GET /api/ai-health/step5-questions
 * Returns AI-generated, condition-specific onboarding questions for Step 5.
 * Locale determined from Accept-Language header.
 */
router.get('/step5-questions', h(aiHealthController.getStep5Questions));

/**
 * POST /api/ai-health/analyze
 * Submit Step 5 responses — enqueues full AI health analysis job (non-blocking).
 */
router.post('/analyze', h(aiHealthController.submitAnalysis));

/**
 * GET /api/ai-health/profile
 * Get the full AI health profile for the current user.
 */
router.get('/profile', h(aiHealthController.getProfile));

/**
 * GET /api/ai-health/profile/status
 * Lightweight poll — returns just the analysis status and version.
 */
router.get('/profile/status', h(aiHealthController.getProfileStatus));

/**
 * GET /api/ai-health/meal-warning
 * Rule-based inline meal conflict warning (instant, no AI call).
 * Query: ?foodName=samosa&ingredients=potato,maida&carbs=30&calories=250
 */
router.get('/meal-warning', h(aiHealthController.getMealWarning));

export default router;
