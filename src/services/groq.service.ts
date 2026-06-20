import logger from '../utils/logger';

interface GroqMessage {
  role: 'system' | 'user' | 'assistant';
  content: string;
}

/**
 * GroqService — Fallback AI provider for health analysis when Gemini is unavailable.
 * Uses Groq's REST API directly (no official SDK dependency needed).
 * Model: llama3-70b-8192 (configurable via GROQ_MODEL env var)
 */
class GroqService {
  private apiKey: string | null;
  private model: string;
  private baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  constructor() {
    this.apiKey = process.env.GROQ_API_KEY || null;
    this.model = process.env.GROQ_MODEL || 'llama3-70b-8192';

    if (!this.apiKey) {
      logger.warn('GROQ_API_KEY is not defined. Groq fallback will be unavailable.');
    }
  }

  isAvailable(): boolean {
    return this.apiKey !== null && this.apiKey.length > 0;
  }

  /**
   * Internal: call the Groq chat completions API with a JSON-focused prompt.
   */
  private async callGroq(messages: GroqMessage[], maxTokens = 2048): Promise<string> {
    if (!this.apiKey) {
      throw new Error('Groq API key is not configured.');
    }

    const response = await fetch(this.baseUrl, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${this.apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: this.model,
        messages,
        max_tokens: maxTokens,
        temperature: 0.3,      // lower temperature for clinical accuracy
        response_format: { type: 'json_object' },
      }),
    });

    if (!response.ok) {
      const errorBody = await response.text();
      throw new Error(`Groq API error ${response.status}: ${errorBody}`);
    }

    const data = await response.json() as any;
    const content = data?.choices?.[0]?.message?.content;
    if (!content) {
      throw new Error('Groq returned an empty response.');
    }
    return content;
  }

  /**
   * Generate condition-specific onboarding questions (Step 5).
   * Returns a JSON array of question objects.
   */
  async generateConditionQuestions(params: {
    age: number;
    gender: string;
    bmi: number;
    conditions: string[];
    severities: string[];
    goals: string[];
    dosha: string;
    allergies: string[];
    isSerious: boolean;
    locale: string;
  }): Promise<any[]> {
    const questionCount = params.isSerious ? '7 to 10' : '4 to 6';

    const systemPrompt = `You are a clinical health assistant generating onboarding questionnaire questions.
You MUST return a valid JSON object with a single key "questions" containing an array of question objects.
Each question object must have:
- "id": string (e.g. "q1")
- "text": string (the question, in ${params.locale} language)
- "type": one of "mcq", "boolean", "scale", "text"
- "options": string[] (required ONLY for type "mcq", 3-4 options)
- "scaleMin": number (required ONLY for type "scale")
- "scaleMax": number (required ONLY for type "scale")
- "scaleLabel": string (required ONLY for type "scale")
Rules:
- Majority of questions MUST be type "mcq".
- Use "boolean" only for simple yes/no facts.
- Use "scale" or "text" sparingly — only when MCQ cannot capture the nuance.
- If isSerious=true, gather maximum clinical data.`;

    const userPrompt = `Patient profile:
- Age: ${params.age}, Gender: ${params.gender}, BMI: ${params.bmi.toFixed(1)}
- Conditions: ${params.conditions.join(', ')} (severities: ${params.severities.join(', ')})
- Goals: ${params.goals.join(', ')}
- Dosha: ${params.dosha}
- Allergies: ${params.allergies.join(', ')}
- Serious patient: ${params.isSerious}
Generate ${questionCount} highly specific follow-up health questions.
Return JSON with key "questions" containing the array.`;

    try {
      const raw = await this.callGroq([
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt },
      ], 1024);

      const parsed = JSON.parse(raw);
      return Array.isArray(parsed.questions) ? parsed.questions : [];
    } catch (error) {
      logger.error('Groq generateConditionQuestions error:', error);
      throw error;
    }
  }

  /**
   * Run a full health analysis and return a structured AIHealthProfile config.
   */
  async analyzeHealthProfile(params: {
    profileSnapshot: Record<string, any>;
    step5Responses: Array<{ questionId: string; questionText: string; answer: any }>;
  }): Promise<any> {
    const systemPrompt = `You are a senior AI health analyst. Analyze the patient profile and generate a comprehensive personalized health configuration.
Return a valid JSON object matching this exact schema:
{
  "isSerious": boolean,
  "conditions": [{ "name": string, "severity": "mild"|"moderate"|"severe" }],
  "riskFlags": string[],
  "mentalHealthIndicators": {
    "stress": "none"|"mild"|"moderate"|"severe",
    "anxiety": "none"|"mild"|"moderate"|"severe",
    "depression": "none"|"mild"|"moderate"|"severe"
  },
  "personalizedSettings": {
    "dailyCalorieGoal": number,
    "dailyProteinGoalG": number,
    "dailyCarbGoalG": number,
    "dailyFatGoalG": number,
    "dailyWaterGoalMl": number,
    "dailyStepGoal": number,
    "sleepGoalHours": number,
    "reminderEnabled": boolean
  },
  "mealPreferences": {
    "avoidIngredients": string[],
    "preferLowGI": boolean,
    "preferLowSodium": boolean,
    "preferLowFat": boolean,
    "recommendedCuisines": string[]
  },
  "doctorPreferences": [{ "specialty": string, "priority": number, "reason": string }],
  "doshaAlignment": { "dosha": string, "aiConfirmed": boolean, "reasoning": string },
  "weeklyInsights": string[],
  "inlineSuggestionConfig": {
    "mealTriggerKeywords": string[],
    "mealWarningTemplate": string,
    "glucoseTargetMin": number,
    "glucoseTargetMax": number,
    "glucoseHighComment": string,
    "glucoseLowComment": string,
    "glucoseNormalComment": string
  }
}
Be clinically accurate. Use evidence-based thresholds. Tone for comments: calm and helpful, never alarmist.`;

    const userPrompt = `Patient data: ${JSON.stringify(params.profileSnapshot, null, 2)}
Step 5 responses: ${JSON.stringify(params.step5Responses, null, 2)}`;

    try {
      const raw = await this.callGroq([
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt },
      ], 2048);

      return JSON.parse(raw);
    } catch (error) {
      logger.error('Groq analyzeHealthProfile error:', error);
      throw error;
    }
  }

  /**
   * Run a lightweight re-analysis — only refreshes weeklyInsights and personalizedSettings.
   */
  async runLightweightReanalysis(params: {
    currentProfile: Record<string, any>;
    recentLogs: Record<string, any>;
    trigger: string;
  }): Promise<{ personalizedSettings: any; weeklyInsights: string[] }> {
    const systemPrompt = `You are a health AI assistant performing a quick adjustment to an existing health profile.
Based on recent activity logs, update only the personalizedSettings and weeklyInsights.
Return a valid JSON object with exactly these two keys:
{
  "personalizedSettings": { same schema as before },
  "weeklyInsights": string[]  (3-5 actionable health tips based on recent trends)
}`;

    const userPrompt = `Current profile: ${JSON.stringify(params.currentProfile, null, 2)}
Recent logs (trigger: ${params.trigger}): ${JSON.stringify(params.recentLogs, null, 2)}`;

    try {
      const raw = await this.callGroq([
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt },
      ], 1024);

      return JSON.parse(raw);
    } catch (error) {
      logger.error('Groq runLightweightReanalysis error:', error);
      throw error;
    }
  }
}

export default new GroqService();
