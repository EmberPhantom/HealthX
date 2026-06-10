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
      let text = response.text().trim();

      // Strip markdown code fences if outputted
      if (text.startsWith('```json')) {
        text = text.substring(7);
      } else if (text.startsWith('```')) {
        text = text.substring(3);
      }
      if (text.endsWith('```')) {
        text = text.substring(0, text.length - 3);
      }
      text = text.trim();

      const parsed = JSON.parse(text);

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
}

export default new GeminiService();
