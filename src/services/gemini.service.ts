import { GoogleGenerativeAI } from '@google/generative-ai';
import logger from '../utils/logger';

class GeminiService {
  private genAI: GoogleGenerativeAI | null = null;

  constructor() {
    const apiKey = process.env.GEMINI_API_KEY;
    if (apiKey) {
      this.genAI = new GoogleGenerativeAI(apiKey);
    } else {
      logger.warn('GEMINI_API_KEY is not defined in environment variables. AI meal identification will run in mock mode.');
    }
  }

  /**
   * Check if Gemini API is available/configured
   */
  isAvailable(): boolean {
    return this.genAI !== null;
  }

  /**
   * Internal: parse AI JSON response, stripping markdown code fences if present.
   */
  private parseJsonResponse(text: string): any {
    let clean = text.trim();
    if (clean.startsWith('```json')) clean = clean.substring(7);
    else if (clean.startsWith('```')) clean = clean.substring(3);
    if (clean.endsWith('```')) clean = clean.substring(0, clean.length - 3);
    return JSON.parse(clean.trim());
  }

  /**
   * Identify a meal using text description and/or image (base64)
   */
  async identifyMeal(input: { text?: string; base64Image?: string; mimeType?: string }): Promise<any> {
    if (!this.genAI) {
      throw new Error('Gemini API is not configured. Enable GEMINI_API_KEY in environment.');
    }

    try {
      const model = this.genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });

      const prompt = `
You are an expert AI nutritionist and food recognition system.
Analyze the provided request (text and/or image of a meal).
Identify the food/meal item and estimate its nutrition details for a standard serving size.
Provide the output in a strict JSON format matching the schema below.
Output ONLY the JSON object, do not wrap in markdown or any other tags.

Response Schema:
{
  "foodName": "Name of the food item",
  "calories": number (estimated total calories),
  "protein": number (estimated protein in grams),
  "fat": number (estimated fat in grams),
  "carbs": number (estimated carbohydrates in grams),
  "ingredients": ["list", "of", "main", "ingredients"],
  "healthScore": number (1 to 10 rating of healthiness),
  "vitamins": ["list", "of", "rich", "vitamins/minerals"],
  "servingSize": "e.g., 1 plate (300g) or 1 piece (120g)",
  "confidence": number (float between 0 and 1 representing confidence in estimation),
  "healthPoints": [
    { "text": "positive or negative health point", "ok": true/false (true for positive benefits, false for concerns like high sodium/sugar) }
  ]
}
`;

      const contents: any[] = [prompt];

      if (input.text) {
        contents.push(`User text description: "${input.text}"`);
      }

      if (input.base64Image && input.mimeType) {
        contents.push({
          inlineData: {
            data: input.base64Image,
            mimeType: input.mimeType,
          },
        });
      }

      const result = await model.generateContent(contents);
      const response = await result.response;
      const parsed = this.parseJsonResponse(response.text());

      // Ensure 'name' is populated for backward compatibility with frontend
      if (parsed && !parsed.name) {
        parsed.name = parsed.foodName;
      }

      return parsed;
    } catch (error) {
      logger.error('Error in Gemini identifyMeal service:', error);
      throw error;
    }
  }

  /**
   * Generate condition-specific onboarding questions (Step 5).
   * Returns an array of question objects tailored to the user's health profile.
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
    if (!this.genAI) {
      throw new Error('Gemini API is not configured.');
    }

    const questionCount = params.isSerious ? '7 to 10' : '4 to 6';

    const prompt = `You are a clinical health assistant generating onboarding questionnaire questions.
Output ONLY a valid JSON array of question objects. Do not wrap in markdown.

Patient profile:
- Age: ${params.age}, Gender: ${params.gender}, BMI: ${params.bmi.toFixed(1)}
- Conditions: ${params.conditions.join(', ') || 'None reported'} (severities: ${params.severities.join(', ') || 'N/A'})
- Goals: ${params.goals.join(', ') || 'General wellness'}
- Dosha: ${params.dosha || 'Not specified'}
- Allergies: ${params.allergies.join(', ') || 'None'}
- Serious patient: ${params.isSerious}

Generate ${questionCount} highly specific follow-up health questions.
Rules:
- MOST questions MUST be type "mcq" with 3-4 clear answer options.
- Use "boolean" only for simple yes/no facts.
- Use "scale" or "text" ONLY when MCQ cannot capture the nuance (rare).
- If isSerious=true, gather maximum clinical data: current readings, medication adherence, symptom frequency.
- All question text must be in locale: ${params.locale}.

Return JSON array format:
[{
  "id": "q1",
  "text": "...",
  "type": "mcq|boolean|scale|text",
  "options": ["option1", "option2", "option3"],
  "scaleMin": 1,
  "scaleMax": 5,
  "scaleLabel": "..."
}]
Only include "options" field for mcq type. Only include scale fields for scale type.`;

    try {
      const model = this.genAI.getGenerativeModel({ model: 'gemini-2.0-flash' });
      const result = await model.generateContent(prompt);
      const parsed = this.parseJsonResponse(result.response.text());
      return Array.isArray(parsed) ? parsed : (Array.isArray(parsed.questions) ? parsed.questions : []);
    } catch (error) {
      logger.error('Gemini generateConditionQuestions error:', error);
      throw error;
    }
  }

  /**
   * Run full health analysis and return a structured AIHealthProfile config JSON.
   */
  async analyzeHealthProfile(params: {
    profileSnapshot: Record<string, any>;
    step5Responses: Array<{ questionId: string; questionText: string; answer: any }>;
  }): Promise<any> {
    if (!this.genAI) {
      throw new Error('Gemini API is not configured.');
    }

    const prompt = `You are a senior AI health analyst. Analyze the patient profile and return a comprehensive personalized health configuration.
Output ONLY a valid JSON object matching the schema below. Do not wrap in markdown.

Patient data: ${JSON.stringify(params.profileSnapshot, null, 2)}
Step 5 responses: ${JSON.stringify(params.step5Responses, null, 2)}

Required JSON schema:
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

Clinical rules to follow:
- Use evidence-based nutritional thresholds (ADA guidelines for diabetes, JNC for hypertension).
- Glucose targets for T2DM: fasting 80-130 mg/dL, post-meal <180 mg/dL.
- All comment strings: calm, informational, helpful — never alarming.
- weeklyInsights: 3-5 actionable tips specific to this patient's conditions.
- mealWarningTemplate may contain {keyword} placeholder.`;

    try {
      const model = this.genAI.getGenerativeModel({ model: 'gemini-2.0-flash' });
      const result = await model.generateContent(prompt);
      return this.parseJsonResponse(result.response.text());
    } catch (error) {
      logger.error('Gemini analyzeHealthProfile error:', error);
      throw error;
    }
  }

  /**
   * Lightweight re-analysis — refresh weeklyInsights and personalizedSettings
   * based on recent log trends, without a full profile re-evaluation.
   */
  async runLightweightReanalysis(params: {
    currentProfile: Record<string, any>;
    recentLogs: Record<string, any>;
    trigger: string;
  }): Promise<{ personalizedSettings: any; weeklyInsights: string[] }> {
    if (!this.genAI) {
      throw new Error('Gemini API is not configured.');
    }

    const prompt = `You are a health AI assistant performing a quick incremental adjustment to a health profile.
Based on the recent activity logs (trigger: ${params.trigger}), adjust personalizedSettings and weeklyInsights only.
Output ONLY a valid JSON object with exactly these two keys. Do not wrap in markdown.

Current profile summary: ${JSON.stringify(params.currentProfile, null, 2)}
Recent logs: ${JSON.stringify(params.recentLogs, null, 2)}

Required JSON:
{
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
  "weeklyInsights": string[]
}
weeklyInsights: 3-5 actionable, personalised tips based on recent log trends.`;

    try {
      const model = this.genAI.getGenerativeModel({ model: 'gemini-2.0-flash' });
      const result = await model.generateContent(prompt);
      return this.parseJsonResponse(result.response.text());
    } catch (error) {
      logger.error('Gemini runLightweightReanalysis error:', error);
      throw error;
    }
  }
}

export default new GeminiService();
