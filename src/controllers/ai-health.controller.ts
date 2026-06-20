import { Response } from 'express';
import { catchAsync } from '../utils/catchAsync';
import { AuthRequest } from '../middlewares/auth.middleware';
import { AppError } from '../utils/AppError';
import aiHealthService, { Step5QA } from '../services/ai-health.service';
import AIHealthProfile from '../models/AIHealthProfile';
import logger from '../utils/logger';

// ── Queue helper (lazy import to avoid circular deps at startup) ───────────────

async function enqueueFullAnalysis(userId: string, step5Responses: Step5QA[]): Promise<string> {
  try {
    const { getAIAnalysisQueue } = await import('../scripts/ai-health.worker');
    const queue = getAIAnalysisQueue();
    const job = await queue.add(
      'full-analysis',
      { userId, step5Responses },
      { jobId: `analysis-${userId}-${Date.now()}` }
    );
    return job.id || 'queued';
  } catch (err) {
    // If Redis/Bull is unavailable, run analysis synchronously (dev mode)
    logger.warn('[ai-health.controller] Queue unavailable — running analysis synchronously');
    aiHealthService.runFullAnalysis(userId, step5Responses).catch((e) =>
      logger.error('[ai-health.controller] Sync fallback analysis error:', e)
    );
    return 'sync';
  }
}

// ── Controllers ───────────────────────────────────────────────────────────────

/**
 * GET /api/ai-health/step5-questions
 * Returns AI-generated onboarding questions tailored to the authenticated user's health profile.
 * Reads locale from the Accept-Language request header.
 */
export const getStep5Questions = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) throw new AppError('User not authenticated', 401);

  // Extract primary locale code from Accept-Language header (e.g. "hi-IN,hi;q=0.9" → "hi")
  const acceptLang = req.headers['accept-language'] || 'en';
  const locale = acceptLang.split(',')[0].split('-')[0].trim() || 'en';

  const questions = await aiHealthService.generateStep5Questions(req.user.userId, locale);

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: { questions, locale },
  });
});

/**
 * POST /api/ai-health/analyze
 * Receives Step 5 Q&A responses and enqueues a full AI health analysis job.
 * Non-blocking — returns immediately with a job status.
 * Body: { responses: [{ questionId, questionText, answer }] }
 */
export const submitAnalysis = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) throw new AppError('User not authenticated', 401);

  const { responses } = req.body;

  if (!Array.isArray(responses)) {
    throw new AppError('responses must be an array of Step 5 Q&A pairs', 400);
  }

  // Validate structure minimally
  const step5Responses: Step5QA[] = responses.map((r: any) => ({
    questionId: String(r.questionId || ''),
    questionText: String(r.questionText || ''),
    answer: r.answer,
  }));

  // Create a pending profile entry immediately so frontend can poll status
  await AIHealthProfile.findOneAndUpdate(
    { userId: req.user.userId },
    {
      $set: {
        status: 'pending',
        step5Responses,
        generatedAt: new Date(),
      },
    },
    { upsert: true, new: true }
  );

  const jobId = await enqueueFullAnalysis(req.user.userId, step5Responses);

  res.status(202).json({
    statusCode: 202,
    status: 'success',
    message: 'Health analysis queued. Your personalised plan will be ready shortly.',
    data: { jobId, analysisStatus: 'pending' },
  });
});

/**
 * GET /api/ai-health/profile
 * Returns the stored AIHealthProfile for the current user.
 * Returns 404 if no profile exists yet (analysis not run or still pending).
 */
export const getProfile = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) throw new AppError('User not authenticated', 401);

  const profile = await aiHealthService.getProfile(req.user.userId);

  if (!profile) {
    return res.status(200).json({
      statusCode: 200,
      status: 'success',
      data: null,
      message: 'No AI health profile found. Complete onboarding to generate one.',
    });
  }

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: profile,
  });
});

/**
 * GET /api/ai-health/profile/status
 * Lightweight poll endpoint — returns just the status field.
 * Used by the Flutter home screen to check if analysis is complete.
 */
export const getProfileStatus = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) throw new AppError('User not authenticated', 401);

  const profile = await AIHealthProfile.findOne({ userId: req.user.userId }).select('status analysisVersion generatedAt');

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: profile
      ? { status: profile.status, version: profile.analysisVersion, generatedAt: profile.generatedAt }
      : { status: 'not_started', version: 0, generatedAt: null },
  });
});

/**
 * GET /api/ai-health/meal-warning
 * Rule-based inline meal conflict check against the user's AIHealthProfile.
 * No AI call — instant response.
 * Query params: foodName, ingredients (comma-separated), carbs, calories
 */
export const getMealWarning = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) throw new AppError('User not authenticated', 401);

  const { foodName, ingredients, carbs, calories } = req.query;

  if (!foodName) throw new AppError('foodName query parameter is required', 400);

  const profile = await AIHealthProfile.findOne({ userId: req.user.userId });

  const warning = aiHealthService.getMealInlineWarning(profile, {
    foodName: String(foodName),
    ingredients: ingredients ? String(ingredients).split(',') : [],
    carbs: carbs ? Number(carbs) : undefined,
    calories: calories ? Number(calories) : undefined,
  });

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: { warning },
  });
});
