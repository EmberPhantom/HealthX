import AIHealthProfile, { IAIHealthProfile, IPersonalizedSettings } from '../models/AIHealthProfile';
import User from '../models/User';
import Patient from '../models/Patient';
import GlucoseLog from '../models/GlucoseLog';
import MealLog from '../models/MealLog';
import WaterLog from '../models/WaterLog';
import StepLog from '../models/StepLog';
import geminiService from './gemini.service';
import groqService from './groq.service';
import logger from '../utils/logger';

// ── Types ─────────────────────────────────────────────────────────────────────

export interface Step5QA {
  questionId: string;
  questionText: string;
  answer: string | number | boolean;
}

export interface MealWarningInput {
  foodName: string;
  ingredients: string[];
  carbs?: number;
  calories?: number;
  healthPoints?: Array<{ text: string; ok: boolean }>;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

const MAX_RETRIES = parseInt(process.env.AI_ANALYSIS_MAX_RETRIES || '3', 10);
const REANALYSIS_THRESHOLD = parseInt(process.env.AI_REANALYSIS_TRIGGER_THRESHOLD || '5', 10);
const RETRY_DELAY_MS = 2000;

async function sleep(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * Build a compact profile snapshot from DB data for AI input.
 */
async function buildProfileSnapshot(userId: string): Promise<Record<string, any>> {
  const user = await User.findById(userId).select('-password -googleRefreshToken');
  const patient = await Patient.findOne({ userId });

  if (!user) throw new Error(`User ${userId} not found`);

  const weight = patient?.weight || 0;
  const height = patient?.height || 0;
  const bmi = weight > 0 && height > 0 ? parseFloat((weight / ((height / 100) ** 2)).toFixed(1)) : 0;

  const conditions: string[] = [];
  const severities: string[] = [];

  if (patient?.isDiabetesPatient) { conditions.push('Type 2 Diabetes'); severities.push('moderate'); }
  if (patient?.isBpPatient) { conditions.push('Hypertension'); severities.push('moderate'); }

  return {
    age: user.age || 30,
    gender: user.gender || 'Others',
    height,
    weight,
    bmi,
    conditions,
    severities,
    goals: user.wellnessGoals || [],
    dosha: user.dominantDosha || '',
    allergies: patient?.allergies || [],
    medications: patient?.medications || [],
    medicalHistory: patient?.medicalHistory || '',
    activityLevel: (user as any).activityLevel ?? 2,
    settings: user.settings,
  };
}

/**
 * Call Gemini with automatic retry → Groq fallback.
 */
async function callWithFallback<T>(
  geminiCall: () => Promise<T>,
  groqCall: () => Promise<T>,
  context: string
): Promise<{ result: T; provider: 'gemini' | 'groq' }> {
  // Try Gemini first with retries
  if (geminiService.isAvailable()) {
    for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
      try {
        const result = await geminiCall();
        return { result, provider: 'gemini' };
      } catch (err) {
        logger.warn(`[${context}] Gemini attempt ${attempt}/${MAX_RETRIES} failed:`, err);
        if (attempt < MAX_RETRIES) await sleep(RETRY_DELAY_MS);
      }
    }
  }

  // Fallback to Groq
  if (groqService.isAvailable()) {
    try {
      logger.info(`[${context}] Falling back to Groq provider.`);
      const result = await groqCall();
      return { result, provider: 'groq' };
    } catch (err) {
      logger.error(`[${context}] Groq fallback also failed:`, err);
      throw err;
    }
  }

  throw new Error(`[${context}] No AI provider available (Gemini and Groq both unavailable).`);
}

// ── Service ───────────────────────────────────────────────────────────────────

class AIHealthService {
  /**
   * Determine if a user's profile qualifies as "serious" (requires deeper questioning).
   * Serious = ≥2 conditions OR at least one condition marked severe.
   */
  private determineIsSerious(conditions: string[], severities: string[]): boolean {
    if (conditions.length >= 2) return true;
    if (severities.some((s) => s === 'severe')) return true;
    return false;
  }

  /**
   * Generate Step 5 onboarding questions tailored to the user's health profile.
   * Called before the user sees Step 5 in the wizard.
   */
  async generateStep5Questions(userId: string, locale: string = 'en'): Promise<any[]> {
    try {
      const snapshot = await buildProfileSnapshot(userId);
      const isSerious = this.determineIsSerious(snapshot.conditions, snapshot.severities);

      const params = {
        age: snapshot.age,
        gender: snapshot.gender,
        bmi: snapshot.bmi,
        conditions: snapshot.conditions,
        severities: snapshot.severities,
        goals: snapshot.goals,
        dosha: snapshot.dosha,
        allergies: snapshot.allergies,
        isSerious,
        locale,
      };

      const { result } = await callWithFallback(
        () => geminiService.generateConditionQuestions(params),
        () => groqService.generateConditionQuestions(params),
        'generateStep5Questions'
      );

      logger.info(`[generateStep5Questions] Generated ${result.length} questions for user ${userId}`);
      return result;
    } catch (error) {
      logger.error(`[generateStep5Questions] Failed for user ${userId}:`, error);
      // Return a minimal default set so the app does not break
      return this.getDefaultStep5Questions();
    }
  }

  /**
   * Fallback static questions used when AI is completely unavailable.
   */
  private getDefaultStep5Questions(): any[] {
    return [
      {
        id: 'q1',
        text: 'How would you rate your overall energy levels throughout the day?',
        type: 'mcq',
        options: ['Very Low', 'Low', 'Moderate', 'High', 'Very High'],
      },
      {
        id: 'q2',
        text: 'How many hours do you sleep on average per night?',
        type: 'mcq',
        options: ['Less than 5 hours', '5-6 hours', '6-7 hours', '7-8 hours', 'More than 8 hours'],
      },
      {
        id: 'q3',
        text: 'Do you currently take any prescription medications?',
        type: 'boolean',
      },
      {
        id: 'q4',
        text: 'How often do you experience significant stress?',
        type: 'mcq',
        options: ['Rarely', 'Occasionally', 'Frequently', 'Almost always'],
      },
    ];
  }

  /**
   * Run full AI health analysis after Step 5 submission.
   * This is called by the Bull worker — not directly from the controller.
   */
  async runFullAnalysis(userId: string, step5Responses: Step5QA[]): Promise<void> {
    // Mark profile as pending
    await AIHealthProfile.findOneAndUpdate(
      { userId },
      { status: 'pending', generatedAt: new Date() },
      { upsert: true, new: true }
    );

    try {
      const snapshot = await buildProfileSnapshot(userId);
      const isSerious = this.determineIsSerious(snapshot.conditions, snapshot.severities);

      let aiOutput: any;
      let provider: 'gemini' | 'groq' | 'formula';

      try {
        const fallbackResult = await callWithFallback(
          () => geminiService.analyzeHealthProfile({ profileSnapshot: snapshot, step5Responses }),
          () => groqService.analyzeHealthProfile({ profileSnapshot: snapshot, step5Responses }),
          'runFullAnalysis'
        );
        aiOutput = fallbackResult.result;
        provider = fallbackResult.provider;
      } catch (aiError) {
        // Last resort: use formula-based defaults
        logger.warn(`[runFullAnalysis] All AI providers failed for ${userId}. Using formula fallback.`);
        aiOutput = this.buildFormulaFallback(snapshot);
        provider = 'formula';
      }

      // Persist the profile
      const updatedProfile = await AIHealthProfile.findOneAndUpdate(
        { userId },
        {
          $set: {
            analysisVersion: 1,
            generatedAt: new Date(),
            provider,
            status: 'complete',
            isSerious,
            conditions: aiOutput.conditions || [],
            riskFlags: aiOutput.riskFlags || [],
            mentalHealthIndicators: aiOutput.mentalHealthIndicators || {},
            personalizedSettings: aiOutput.personalizedSettings || {},
            mealPreferences: aiOutput.mealPreferences || {},
            doctorPreferences: aiOutput.doctorPreferences || [],
            doshaAlignment: aiOutput.doshaAlignment || {},
            weeklyInsights: aiOutput.weeklyInsights || [],
            inlineSuggestionConfig: aiOutput.inlineSuggestionConfig || {},
            step5Responses,
            rawAIOutput: JSON.stringify(aiOutput),
            logEntrySinceLastAnalysis: 0,
          },
        },
        { upsert: true, new: true }
      );

      // Apply personalized settings back to the User document
      await this.applyPersonalization(userId, updatedProfile as unknown as IAIHealthProfile);
      logger.info(`[runFullAnalysis] Completed for user ${userId} via ${provider}`);
    } catch (error) {
      // Mark profile as error so it can be retried
      await AIHealthProfile.findOneAndUpdate({ userId }, { status: 'error' });
      logger.error(`[runFullAnalysis] Fatal error for user ${userId}:`, error);
      throw error;
    }
  }

  /**
   * Apply AI-derived personalizedSettings back to the User.settings document.
   */
  async applyPersonalization(userId: string, profile: IAIHealthProfile): Promise<void> {
    const ps = profile.personalizedSettings as IPersonalizedSettings;
    if (!ps) return;

    await User.findByIdAndUpdate(userId, {
      $set: {
        'settings.dailyCalorieGoal': ps.dailyCalorieGoal,
        'settings.dailyProteinGoalG': ps.dailyProteinGoalG,
        'settings.dailyCarbGoalG': ps.dailyCarbGoalG,
        'settings.dailyFatGoalG': ps.dailyFatGoalG,
        'settings.dailyWaterGoalMl': ps.dailyWaterGoalMl,
        'settings.dailyStepGoal': ps.dailyStepGoal,
        'settings.reminderEnabled': ps.reminderEnabled,
        // If dosha was AI-confirmed, update it
        ...(profile.doshaAlignment?.aiConfirmed && profile.doshaAlignment?.dosha
          ? { dominantDosha: profile.doshaAlignment.dosha }
          : {}),
        // Merge AI-suggested wellness goals (additive, not replacing)
        ...(profile.conditions?.length > 0
          ? {
              wellnessGoals: await this.mergeWellnessGoals(
                userId,
                profile.conditions.map((c) => c.name)
              ),
            }
          : {}),
      },
    });
  }

  /**
   * Merge AI-inferred wellness goals into the user's existing list without duplicates.
   */
  private async mergeWellnessGoals(userId: string, conditions: string[]): Promise<string[]> {
    const user = await User.findById(userId).select('wellnessGoals');
    const existing = new Set(user?.wellnessGoals || []);

    const conditionGoalMap: Record<string, string> = {
      'Type 2 Diabetes': 'Manage Diabetes',
      Hypertension: 'Manage Blood Pressure',
      Obesity: 'Lose Weight',
      'Thyroid Disorder': 'Improve Energy',
      PCOS: 'Hormonal Balance',
      'Heart Disease': 'Improve Heart Health',
      Depression: 'Reduce Stress',
      Anxiety: 'Reduce Stress',
    };

    for (const cond of conditions) {
      const mapped = conditionGoalMap[cond];
      if (mapped) existing.add(mapped);
    }

    return Array.from(existing);
  }

  /**
   * Lightweight re-analysis — only refreshes personalizedSettings and weeklyInsights.
   * Called by Bull worker on log threshold / weekly cron.
   */
  async runLightweightReanalysis(userId: string, trigger: string): Promise<void> {
    const profile = await AIHealthProfile.findOne({ userId });
    if (!profile) {
      logger.warn(`[runLightweightReanalysis] No AIHealthProfile found for ${userId}. Skipping.`);
      return;
    }

    try {
      // Build a compact recent-log summary
      const since = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000); // last 7 days
      const [recentGlucose, recentMeals, recentSteps, recentWater] = await Promise.all([
        GlucoseLog.find({ userId, loggedAt: { $gte: since } }).sort({ loggedAt: -1 }).limit(20),
        MealLog.find({ userId, loggedAt: { $gte: since } }).sort({ loggedAt: -1 }).limit(20),
        StepLog.find({ userId }).sort({ dateKey: -1 }).limit(7),
        WaterLog.find({ userId, loggedAt: { $gte: since } }).sort({ loggedAt: -1 }).limit(7),
      ]);

      const recentLogs = { glucose: recentGlucose, meals: recentMeals, steps: recentSteps, water: recentWater };
      const currentProfileSummary = {
        conditions: profile.conditions,
        isSerious: profile.isSerious,
        personalizedSettings: profile.personalizedSettings,
        riskFlags: profile.riskFlags,
      };

      const params = { currentProfile: currentProfileSummary, recentLogs, trigger };

      let updated: { personalizedSettings: any; weeklyInsights: string[] };
      let provider: 'gemini' | 'groq';

      try {
        const res = await callWithFallback(
          () => geminiService.runLightweightReanalysis(params),
          () => groqService.runLightweightReanalysis(params),
          'runLightweightReanalysis'
        );
        updated = res.result;
        provider = res.provider;
      } catch {
        // Skip update silently if all AI fails — don't break user experience
        logger.warn(`[runLightweightReanalysis] AI unavailable for ${userId}. Skipping update.`);
        return;
      }

      await AIHealthProfile.findOneAndUpdate(
        { userId },
        {
          $set: {
            personalizedSettings: updated.personalizedSettings,
            weeklyInsights: updated.weeklyInsights,
            generatedAt: new Date(),
            provider,
            logEntrySinceLastAnalysis: 0,
          },
          $inc: { analysisVersion: 1 },
        }
      );

      // Sync updated settings to User document
      await this.applyPersonalization(userId, (await AIHealthProfile.findOne({ userId })) as IAIHealthProfile);
      logger.info(`[runLightweightReanalysis] Refreshed profile for ${userId} via ${provider} (trigger: ${trigger})`);
    } catch (error) {
      logger.error(`[runLightweightReanalysis] Error for user ${userId}:`, error);
    }
  }

  /**
   * Increment the log entry counter and trigger re-analysis if threshold is reached.
   * Called after any significant log event (meal, glucose, weight, etc.).
   */
  async onLogEntry(userId: string, trigger: string): Promise<void> {
    const profile = await AIHealthProfile.findOneAndUpdate(
      { userId },
      { $inc: { logEntrySinceLastAnalysis: 1 } },
      { new: true }
    );

    if (!profile) return;

    if (profile.logEntrySinceLastAnalysis >= REANALYSIS_THRESHOLD) {
      // Queue lightweight reanalysis (imported dynamically to avoid circular deps with worker)
      try {
        const { getAIReanalysisQueue } = await import('../scripts/ai-health.worker');
        const queue = getAIReanalysisQueue();
        await queue.add('lightweight-reanalysis', { userId, trigger }, { attempts: 2, backoff: { type: 'fixed', delay: 5000 } });
        logger.info(`[onLogEntry] Queued lightweight reanalysis for ${userId} (trigger: ${trigger})`);
      } catch (err) {
        logger.warn(`[onLogEntry] Could not queue reanalysis for ${userId}:`, err);
      }
    }
  }

  /**
   * Get a meal inline warning based on stored AIHealthProfile config.
   * Pure rule-based — no AI call, instant response.
   * Returns null if no warning is applicable.
   */
  getMealInlineWarning(profile: IAIHealthProfile | null, meal: MealWarningInput): string | null {
    if (!profile || profile.status !== 'complete') return null;

    const cfg = profile.inlineSuggestionConfig;
    if (!cfg?.mealTriggerKeywords?.length) return null;

    // Check ingredients + food name against trigger keywords
    const searchText = [
      meal.foodName,
      ...(meal.ingredients || []),
      ...(meal.healthPoints?.filter((hp) => !hp.ok).map((hp) => hp.text) || []),
    ]
      .join(' ')
      .toLowerCase();

    const matchedKeyword = cfg.mealTriggerKeywords.find((kw) =>
      searchText.includes(kw.toLowerCase())
    );

    if (!matchedKeyword) return null;

    // Build warning from template
    const template = cfg.mealWarningTemplate || 'Heads up — {keyword} detected in this item.';
    return template.replace('{keyword}', matchedKeyword);
  }

  /**
   * Get a glucose reading inline comment based on stored AIHealthProfile config.
   * Pure rule-based — no AI call, instant response.
   * Returns null if user has no AI profile or is not diabetic.
   */
  getGlucoseInlineComment(
    profile: IAIHealthProfile | null,
    glucoseLevel: number,
    readingType: string
  ): string | null {
    if (!profile || profile.status !== 'complete') return null;

    // Only show for users with diabetes in their AI profile
    const hasDiabetes = profile.conditions?.some((c) =>
      c.name.toLowerCase().includes('diabet')
    );
    if (!hasDiabetes) return null;

    const cfg = profile.inlineSuggestionConfig;
    if (!cfg) return null;

    // Use reading-type aware thresholds
    let targetMax = cfg.glucoseTargetMax ?? 140;
    let targetMin = cfg.glucoseTargetMin ?? 70;

    // Post-meal threshold is more permissive per ADA guidelines
    if (readingType === 'post_meal') {
      targetMax = Math.max(targetMax, 180);
    }

    if (glucoseLevel > targetMax) {
      return cfg.glucoseHighComment || `Reading of ${glucoseLevel} mg/dL is above your target. A short walk can help.`;
    } else if (glucoseLevel < targetMin) {
      return cfg.glucoseLowComment || `Reading of ${glucoseLevel} mg/dL is below target. Consider a small snack.`;
    } else {
      return cfg.glucoseNormalComment || `Good reading — ${glucoseLevel} mg/dL is within your target range.`;
    }
  }

  /**
   * Retrieve the AIHealthProfile for a user.
   */
  async getProfile(userId: string): Promise<IAIHealthProfile | null> {
    return AIHealthProfile.findOne({ userId }).select('-rawAIOutput') as Promise<IAIHealthProfile | null>;
  }

  /**
   * Formula-based fallback when all AI providers fail.
   * Mirrors the logic already in onboarding.service.ts but extended.
   */
  private buildFormulaFallback(snapshot: Record<string, any>): any {
    const { weight, height, age, gender, goals = [], conditions = [] } = snapshot;
    const lowerGoals = goals.map((g: string) => g.toLowerCase());
    const isHypertensive = conditions.includes('Hypertension');
    const isDiabetic = conditions.includes('Type 2 Diabetes');

    let bmr = weight > 0 && height > 0
      ? 10 * weight + 6.25 * height - 5 * age + (gender === 'Male' ? 5 : gender === 'Female' ? -161 : -78)
      : 1800;

    const multipliers = [1.2, 1.375, 1.55, 1.725, 1.9];
    const tdee = bmr * multipliers[Math.min(snapshot.activityLevel ?? 2, 4)];

    let dailyCalorieGoal = Math.round(tdee);
    if (lowerGoals.includes('lose weight')) dailyCalorieGoal = Math.round(tdee - 500);
    if (lowerGoals.includes('build muscle')) dailyCalorieGoal = Math.round(tdee + 300);
    dailyCalorieGoal = Math.min(Math.max(dailyCalorieGoal, 1200), 5000);

    const dailyProteinGoalG = Math.round(Math.min(Math.max(1.2 * weight, 50), 300));
    const dailyFatGoalG = Math.round((dailyCalorieGoal * 0.25) / 9);
    const dailyCarbGoalG = Math.round((dailyCalorieGoal - dailyProteinGoalG * 4 - dailyFatGoalG * 9) / 4);
    const dailyWaterGoalMl = Math.round(Math.min(Math.max(weight * 35, 2000), 5000));
    const dailyStepGoal = isDiabetic ? 7000 : 8000;

    return {
      isSerious: false,
      conditions: conditions.map((c: string) => ({ name: c, severity: 'moderate' })),
      riskFlags: [],
      mentalHealthIndicators: { stress: 'none', anxiety: 'none', depression: 'none' },
      personalizedSettings: {
        dailyCalorieGoal,
        dailyProteinGoalG,
        dailyCarbGoalG,
        dailyFatGoalG,
        dailyWaterGoalMl,
        dailyStepGoal,
        sleepGoalHours: 8,
        reminderEnabled: false,
      },
      mealPreferences: {
        avoidIngredients: [],
        preferLowGI: isDiabetic,
        preferLowSodium: isHypertensive,
        preferLowFat: false,
        recommendedCuisines: [],
      },
      doctorPreferences: [
        ...(isDiabetic ? [{ specialty: 'Endocrinologist', priority: 1, reason: 'Diabetes management' }] : []),
        ...(isHypertensive ? [{ specialty: 'Cardiologist', priority: isDiabetic ? 2 : 1, reason: 'Hypertension management' }] : []),
      ],
      doshaAlignment: { dosha: snapshot.dosha || '', aiConfirmed: false, reasoning: 'Formula fallback' },
      weeklyInsights: [
        'Log your meals consistently to track your nutrition goals.',
        'Stay hydrated — aim to meet your daily water target.',
        'Regular light exercise helps manage blood sugar and blood pressure.',
      ],
      inlineSuggestionConfig: {
        mealTriggerKeywords: isDiabetic ? ['sugar', 'refined', 'white rice', 'maida', 'sweet'] : [],
        mealWarningTemplate: 'Heads up — {keyword} found in this item. Consider a smaller portion.',
        glucoseTargetMin: 70,
        glucoseTargetMax: isDiabetic ? 140 : 100,
        glucoseHighComment: 'Your reading is above target. A short walk after meals can help lower it.',
        glucoseLowComment: 'Your reading is below target. Have a small snack to stabilise your levels.',
        glucoseNormalComment: 'Great reading — within your target range. Keep it up!',
      },
    };
  }
}

export default new AIHealthService();
