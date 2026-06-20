import aiHealthService from '../../../services/ai-health.service';
import geminiService from '../../../services/gemini.service';
import groqService from '../../../services/groq.service';
import User from '../../../models/User';
import Patient from '../../../models/Patient';
import AIHealthProfile from '../../../models/AIHealthProfile';
import GlucoseLog from '../../../models/GlucoseLog';
import MealLog from '../../../models/MealLog';
import WaterLog from '../../../models/WaterLog';
import StepLog from '../../../models/StepLog';
import { Types } from 'mongoose';

// Set low retries to make fallback tests run instantly instead of sleeping
process.env.AI_ANALYSIS_MAX_RETRIES = '1';

// Mock the AI services to prevent network calls
jest.mock('../../../services/gemini.service');
jest.mock('../../../services/groq.service');

describe('AIHealthService', () => {
  let userId: string;

  beforeEach(async () => {
    jest.clearAllMocks();
    userId = new Types.ObjectId().toString();

    // Clear DB collections before each test
    await User.deleteMany({});
    await Patient.deleteMany({});
    await AIHealthProfile.deleteMany({});
    await GlucoseLog.deleteMany({});
    await MealLog.deleteMany({});
    await WaterLog.deleteMany({});
    await StepLog.deleteMany({});

    // Setup mock availability
    (geminiService.isAvailable as jest.Mock).mockReturnValue(true);
    (groqService.isAvailable as jest.Mock).mockReturnValue(true);
  });

  describe('generateStep5Questions', () => {
    it('should generate questions from Gemini when available', async () => {
      // Setup User and Patient in DB
      await User.create({
        _id: userId,
        name: 'Test User',
        email: 'test@example.com',
        phone: '+1234567890',
        password: 'password123',
        age: 35,
        gender: 'Male',
        wellnessGoals: ['Lose Weight'],
        dominantDosha: 'Pitta',
      });
      await Patient.create({
        userId,
        weight: 80,
        height: 180,
        isDiabetesPatient: true,
        isBpPatient: false,
        allergies: ['Milk'],
      });

      const mockQuestions = [
        { id: 'q1', text: 'How long have you had diabetes?', type: 'mcq', options: ['<1yr', '1-5yrs', '5yrs+'] }
      ];

      (geminiService.generateConditionQuestions as jest.Mock).mockResolvedValue(mockQuestions);

      const questions = await aiHealthService.generateStep5Questions(userId, 'en');

      expect(questions).toEqual(mockQuestions);
      expect(geminiService.generateConditionQuestions).toHaveBeenCalledWith(expect.objectContaining({
        age: 35,
        gender: 'Male',
        bmi: 24.7, // 80 / (1.8^2)
        conditions: ['Type 2 Diabetes'],
        goals: ['Lose Weight'],
        dosha: 'Pitta',
        allergies: ['Milk'],
        isSerious: false, // only 1 condition
        locale: 'en',
      }));
    });

    it('should fallback to Groq when Gemini fails', async () => {
      await User.create({
        _id: userId,
        name: 'Test User',
        email: 'test@example.com',
        phone: '+1234567890',
        password: 'password123',
      });

      (geminiService.generateConditionQuestions as jest.Mock).mockRejectedValue(new Error('Gemini Offline'));
      const mockGroqQuestions = [
        { id: 'q_groq', text: 'How are you today?', type: 'mcq', options: ['Good', 'Bad'] }
      ];
      (groqService.generateConditionQuestions as jest.Mock).mockResolvedValue(mockGroqQuestions);

      const questions = await aiHealthService.generateStep5Questions(userId, 'en');

      expect(questions).toEqual(mockGroqQuestions);
      expect(geminiService.generateConditionQuestions).toHaveBeenCalled();
      expect(groqService.generateConditionQuestions).toHaveBeenCalled();
    });

    it('should fallback to static questions when both Gemini and Groq fail', async () => {
      await User.create({
        _id: userId,
        name: 'Test User',
        email: 'test@example.com',
        phone: '+1234567890',
        password: 'password123',
      });

      (geminiService.generateConditionQuestions as jest.Mock).mockRejectedValue(new Error('Gemini Offline'));
      (groqService.generateConditionQuestions as jest.Mock).mockRejectedValue(new Error('Groq Offline'));

      const questions = await aiHealthService.generateStep5Questions(userId, 'en');

      expect(questions).toHaveLength(4);
      expect(questions[0].id).toBe('q1');
    });
  });

  describe('runFullAnalysis', () => {
    const mockStep5Responses = [
      { questionId: 'q1', questionText: 'Q1', answer: 'Answer 1' }
    ];

    it('should analyze health profile and update user settings with Gemini', async () => {
      const user = await User.create({
        _id: userId,
        name: 'Test User',
        email: 'test@example.com',
        phone: '+1234567890',
        password: 'password123',
        settings: {
          dailyCalorieGoal: 2000,
          dailyWaterGoalMl: 2500,
        }
      });
      await Patient.create({ userId, weight: 70, height: 170 });

      const mockAIProfile = {
        conditions: [{ name: 'Type 2 Diabetes', severity: 'moderate' }],
        riskFlags: ['diabetes_risk'],
        mentalHealthIndicators: { stress: 'mild', anxiety: 'none', depression: 'none' },
        personalizedSettings: {
          dailyCalorieGoal: 1800,
          dailyProteinGoalG: 120,
          dailyCarbGoalG: 180,
          dailyFatGoalG: 60,
          dailyWaterGoalMl: 3000,
          dailyStepGoal: 7000,
          sleepGoalHours: 8,
          reminderEnabled: true,
        },
        mealPreferences: {
          avoidIngredients: ['sugar'],
          preferLowGI: true,
          preferLowSodium: false,
          preferLowFat: false,
          recommendedCuisines: ['Indian'],
        },
        doctorPreferences: [{ specialty: 'Endocrinologist', priority: 1, reason: 'Diabetes management' }],
        doshaAlignment: { dosha: 'Kapha', aiConfirmed: true, reasoning: 'Confirmed dosha' },
        weeklyInsights: ['Tip 1', 'Tip 2'],
        inlineSuggestionConfig: {
          mealTriggerKeywords: ['sugar'],
          mealWarningTemplate: 'Sugar warning',
          glucoseTargetMin: 70,
          glucoseTargetMax: 140,
        }
      };

      (geminiService.analyzeHealthProfile as jest.Mock).mockResolvedValue(mockAIProfile);

      await aiHealthService.runFullAnalysis(userId, mockStep5Responses);

      // Verify AIHealthProfile document created
      const profile = await AIHealthProfile.findOne({ userId });
      expect(profile).toBeDefined();
      expect(profile?.status).toBe('complete');
      expect(profile?.provider).toBe('gemini');
      expect(profile?.conditions[0].name).toBe('Type 2 Diabetes');

      // Verify User settings updated
      const updatedUser = await User.findById(userId);
      expect(updatedUser?.settings.dailyCalorieGoal).toBe(1800);
      expect(updatedUser?.settings.dailyWaterGoalMl).toBe(3000);
      expect(updatedUser?.dominantDosha).toBe('Kapha');
      expect(updatedUser?.wellnessGoals).toContain('Manage Diabetes');
    });

    it('should fallback to formula-based parameters if AI analysis fails completely', async () => {
      const user = await User.create({
        _id: userId,
        name: 'Test User',
        email: 'test@example.com',
        phone: '+1234567890',
        password: 'password123',
        settings: {
          dailyCalorieGoal: 2000,
          dailyWaterGoalMl: 2500,
        }
      });
      await Patient.create({ userId, weight: 70, height: 170 });

      (geminiService.analyzeHealthProfile as jest.Mock).mockRejectedValue(new Error('Gemini Offline'));
      (groqService.analyzeHealthProfile as jest.Mock).mockRejectedValue(new Error('Groq Offline'));

      await aiHealthService.runFullAnalysis(userId, mockStep5Responses);

      const profile = await AIHealthProfile.findOne({ userId });
      expect(profile).toBeDefined();
      expect(profile?.status).toBe('complete');
      expect(profile?.provider).toBe('formula'); // used formula fallback!
      expect(profile?.personalizedSettings.dailyWaterGoalMl).toBe(2450); // 70 * 35 = 2450ml

      const updatedUser = await User.findById(userId);
      expect(updatedUser?.settings.dailyWaterGoalMl).toBe(2450);
    });
  });

  describe('runLightweightReanalysis', () => {
    it('should run lightweight reanalysis and update insights/settings', async () => {
      await User.create({
        _id: userId,
        name: 'Test User',
        email: 'test@example.com',
        phone: '+1234567890',
        password: 'password123',
        settings: {
          dailyCalorieGoal: 2000,
        }
      });

      // Create existing profile
      await AIHealthProfile.create({
        userId,
        status: 'complete',
        analysisVersion: 1,
        conditions: [],
        personalizedSettings: {
          dailyCalorieGoal: 2000,
          dailyProteinGoalG: 100,
          dailyCarbGoalG: 250,
          dailyFatGoalG: 65,
          dailyWaterGoalMl: 3000,
          dailyStepGoal: 8000,
          sleepGoalHours: 8,
          reminderEnabled: false,
        },
      });

      // Seed some log data
      await WaterLog.create({ userId, amount: 250, loggedAt: new Date() });
      await StepLog.create({ userId, steps: 12000, dateKey: '2026-06-15' });

      const mockReanalysisResult = {
        personalizedSettings: {
          dailyCalorieGoal: 1900,
          dailyProteinGoalG: 100,
          dailyCarbGoalG: 250,
          dailyFatGoalG: 65,
          dailyWaterGoalMl: 3000,
          dailyStepGoal: 9000, // steps increased based on active trend
          sleepGoalHours: 8,
          reminderEnabled: false,
        },
        weeklyInsights: ['Active week! Step goal increased.']
      };

      (geminiService.runLightweightReanalysis as jest.Mock).mockResolvedValue(mockReanalysisResult);

      await aiHealthService.runLightweightReanalysis(userId, 'test-trigger');

      const profile = await AIHealthProfile.findOne({ userId });
      expect(profile?.analysisVersion).toBe(2);
      expect(profile?.personalizedSettings.dailyStepGoal).toBe(9000);
      expect(profile?.weeklyInsights[0]).toBe('Active week! Step goal increased.');

      const updatedUser = await User.findById(userId);
      expect(updatedUser?.settings.dailyStepGoal).toBe(9000);
    });
  });

  describe('getMealInlineWarning', () => {
    it('should return warning when keyword matches meal ingredients', () => {
      const mockProfile = {
        status: 'complete',
        inlineSuggestionConfig: {
          mealTriggerKeywords: ['gluten', 'refined carbs'],
          mealWarningTemplate: 'Warning: contains {keyword} which should be avoided.',
        }
      } as any;

      const warning = aiHealthService.getMealInlineWarning(mockProfile, {
        foodName: 'Wheat Cake',
        ingredients: ['flour', 'gluten', 'sugar syrup'],
        calories: 300,
      });

      expect(warning).toBe('Warning: contains gluten which should be avoided.');
    });

    it('should return null when no keywords match', () => {
      const mockProfile = {
        status: 'complete',
        inlineSuggestionConfig: {
          mealTriggerKeywords: ['sugar'],
          mealWarningTemplate: 'Warning: contains {keyword}',
        }
      } as any;

      const warning = aiHealthService.getMealInlineWarning(mockProfile, {
        foodName: 'Salad',
        ingredients: ['lettuce', 'cucumber'],
      });

      expect(warning).toBeNull();
    });
  });

  describe('getGlucoseInlineComment', () => {
    const mockProfile = {
      status: 'complete',
      conditions: [{ name: 'Type 2 Diabetes', severity: 'moderate' }],
      inlineSuggestionConfig: {
        glucoseTargetMin: 70,
        glucoseTargetMax: 140,
        glucoseHighComment: 'Too high!',
        glucoseLowComment: 'Too low!',
        glucoseNormalComment: 'All good!',
      }
    } as any;

    it('should return low comment when glucose is below minimum', () => {
      const comment = aiHealthService.getGlucoseInlineComment(mockProfile, 60, 'fasting');
      expect(comment).toBe('Too low!');
    });

    it('should return high comment when glucose is above maximum for fasting', () => {
      const comment = aiHealthService.getGlucoseInlineComment(mockProfile, 150, 'fasting');
      expect(comment).toBe('Too high!');
    });

    it('should return normal comment when glucose is in range', () => {
      const comment = aiHealthService.getGlucoseInlineComment(mockProfile, 100, 'fasting');
      expect(comment).toBe('All good!');
    });

    it('should adapt to post-meal threshold (ADA recommends < 180)', () => {
      // 160 is above 140 target max, but post_meal threshold is 180, so 160 post_meal is Normal.
      const comment = aiHealthService.getGlucoseInlineComment(mockProfile, 160, 'post_meal');
      expect(comment).toBe('All good!');
    });

    it('should return high comment if post_meal exceeds 180', () => {
      const comment = aiHealthService.getGlucoseInlineComment(mockProfile, 190, 'post_meal');
      expect(comment).toBe('Too high!');
    });

    it('should return null for non-diabetic users', () => {
      const nonDiabeticProfile = {
        ...mockProfile,
        conditions: [],
      } as any;
      const comment = aiHealthService.getGlucoseInlineComment(nonDiabeticProfile, 200, 'fasting');
      expect(comment).toBeNull();
    });
  });
});
