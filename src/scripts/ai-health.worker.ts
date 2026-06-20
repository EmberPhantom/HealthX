/**
 * AI Health Background Worker
 *
 * Manages two BullMQ queues:
 *   1. ai-health-analysis    — Full health analysis triggered once at onboarding completion
 *   2. ai-reanalysis         — Lightweight re-analysis triggered by log thresholds & weekly cron
 *
 * The queues are exported so controllers can enqueue jobs directly.
 * The workers (processors) are started by calling startAIHealthWorkers().
 * This is called from server.ts after DB + Redis are ready.
 */

import { Queue, Worker, Job, QueueEvents } from 'bullmq';
import { getRedisClient } from '../config/redis';
import aiHealthService from '../services/ai-health.service';
import AIHealthProfile from '../models/AIHealthProfile';
import notificationDispatcher from '../services/notification.service';
import logger from '../utils/logger';

// ── Queue definitions ─────────────────────────────────────────────────────────

let aiAnalysisQueue: Queue | null = null;
let aiReanalysisQueue: Queue | null = null;

const getRedisConnection = () => {
  const redisUrl = process.env.REDIS_URL || 'redis://localhost:6379';
  const password = process.env.REDIS_PASSWORD || undefined;

  // BullMQ needs its own connection object (not a shared ioredis instance)
  return {
    host: redisUrl.replace(/^redis:\/\//, '').split(':')[0] || 'localhost',
    port: parseInt(redisUrl.split(':').pop() || '6379', 10),
    password,
  };
};

/**
 * Lazy-initialise the queues (only when Redis is available).
 * Safe to call multiple times — returns the same instance.
 */
export function getAIAnalysisQueue(): Queue {
  if (!aiAnalysisQueue) {
    aiAnalysisQueue = new Queue('ai-health-analysis', {
      connection: getRedisConnection(),
      defaultJobOptions: {
        attempts: parseInt(process.env.AI_ANALYSIS_MAX_RETRIES || '3', 10),
        backoff: { type: 'exponential', delay: 5000 },
        removeOnComplete: { count: 100 },
        removeOnFail: { count: 50 },
      },
    });
    logger.info('[AIWorker] ai-health-analysis queue ready');
  }
  return aiAnalysisQueue;
}

export function getAIReanalysisQueue(): Queue {
  if (!aiReanalysisQueue) {
    aiReanalysisQueue = new Queue('ai-reanalysis', {
      connection: getRedisConnection(),
      defaultJobOptions: {
        attempts: 2,
        backoff: { type: 'fixed', delay: 5000 },
        removeOnComplete: { count: 200 },
        removeOnFail: { count: 50 },
      },
    });
    logger.info('[AIWorker] ai-reanalysis queue ready');
  }
  return aiReanalysisQueue;
}

// Also export as named aliases for import in ai-health.service.ts
export { aiReanalysisQueue };

// ── Workers ───────────────────────────────────────────────────────────────────

/**
 * Process full health analysis jobs.
 * Job data: { userId: string, step5Responses: Step5QA[] }
 */
async function processFullAnalysis(job: Job): Promise<void> {
  const { userId, step5Responses = [] } = job.data;
  logger.info(`[AIWorker] Processing full analysis for user ${userId} (job ${job.id})`);

  await aiHealthService.runFullAnalysis(userId, step5Responses);
  logger.info(`[AIWorker] Full analysis complete for user ${userId}`);

  // Notify user that their AI health profile is ready
  notificationDispatcher.dispatch({
    userId,
    title: 'Your Health Profile is Ready! 🧠',
    body: 'HealthX AI has analysed your health data and personalised your plan — tap to explore your insights.',
    type: 'success',
    category: 'health',
    data: { type: 'health_alert', screen: 'health_profile' },
  }).catch(() => {});
}

/**
 * Process lightweight re-analysis jobs.
 * Job data: { userId: string, trigger: string }
 */
async function processReanalysis(job: Job): Promise<void> {
  const { userId, trigger = 'unknown' } = job.data;

  if (trigger === 'weekly_cron' && !userId) {
    logger.info('[AIWorker] Weekly cron triggered — dispatching re-analysis jobs for all users');
    try {
      const profiles = await AIHealthProfile.find({ status: 'complete' }).select('userId');
      const queue = getAIReanalysisQueue();
      for (const p of profiles) {
        await queue.add(
          'lightweight-reanalysis',
          { userId: p.userId.toString(), trigger: 'weekly_cron' },
          { attempts: 2, backoff: { type: 'fixed', delay: 5000 } }
        );
      }
      logger.info(`[AIWorker] Successfully enqueued weekly re-analysis for ${profiles.length} users`);
    } catch (err) {
      logger.error('[AIWorker] Failed to dispatch weekly re-analysis jobs:', err);
    }
    return;
  }

  logger.info(`[AIWorker] Processing re-analysis for user ${userId}, trigger: ${trigger} (job ${job.id})`);
  await aiHealthService.runLightweightReanalysis(userId, trigger);
  logger.info(`[AIWorker] Re-analysis complete for user ${userId}`);

  // Notify user their health profile has been updated (skip weekly_cron silent runs)
  if (trigger !== 'weekly_cron') {
    notificationDispatcher.dispatch({
      userId,
      title: 'Health Profile Updated 📊',
      body: 'Your HealthX profile has been updated based on your recent health logs.',
      type: 'info',
      category: 'health',
      data: { type: 'health_alert', screen: 'health_profile' },
    }).catch(() => {});
  }
}

// ── Weekly Cron ───────────────────────────────────────────────────────────────

/**
 * Schedule a weekly cron job that enqueues lightweight re-analysis
 * for all users who have a complete AIHealthProfile.
 * Runs every Sunday at midnight server time (cron: '0 0 * * 0').
 */
async function scheduleWeeklyCron(): Promise<void> {
  const queue = getAIReanalysisQueue();

  // BullMQ repeatable jobs — idempotent, only registers once
  await queue.add(
    'weekly-reanalysis-cron',
    { trigger: 'weekly_cron' },
    {
      repeat: { pattern: '0 0 * * 0' }, // Every Sunday at 00:00
      jobId: 'weekly-reanalysis-cron',  // Stable ID prevents duplicates
    }
  );

  logger.info('[AIWorker] Weekly re-analysis cron registered (Sundays 00:00)');
}

// ── Startup ───────────────────────────────────────────────────────────────────

/**
 * Start both AI health workers.
 * Called from server.ts after Redis is connected.
 * Concurrency is intentionally low (2) to respect AI API rate limits.
 */
export async function startAIHealthWorkers(): Promise<void> {
  const redis = getRedisClient();
  if (!redis) {
    logger.warn('[AIWorker] Redis not available — AI health workers will not start. AI personalization will run synchronously on demand.');
    return;
  }

  const connection = getRedisConnection();

  // Full-analysis worker — concurrency 1 (heavy API calls, avoid rate-limiting)
  const analysisWorker = new Worker('ai-health-analysis', processFullAnalysis, {
    connection,
    concurrency: 1,
  });

  // Re-analysis worker — concurrency 2 (lighter calls)
  const reanalysisWorker = new Worker('ai-reanalysis', processReanalysis, {
    connection,
    concurrency: 2,
  });

  // Worker event logging
  [
    { worker: analysisWorker, name: 'ai-health-analysis' },
    { worker: reanalysisWorker, name: 'ai-reanalysis' },
  ].forEach(({ worker, name }) => {
    worker.on('completed', (job) => {
      logger.info(`[AIWorker:${name}] Job ${job.id} completed`);
    });

    worker.on('failed', (job, err) => {
      logger.error(`[AIWorker:${name}] Job ${job?.id} failed:`, err?.message);
    });

    worker.on('error', (err) => {
      logger.error(`[AIWorker:${name}] Worker error:`, err);
    });
  });

  // Register weekly cron
  await scheduleWeeklyCron();

  logger.info('[AIWorker] AI health workers started successfully');
}
