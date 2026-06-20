import mongoose, { Schema, Document, Types } from 'mongoose';

// ── Sub-document interfaces ──────────────────────────────────────────────────

export interface ICondition {
  name: string;
  severity: 'mild' | 'moderate' | 'severe';
}

export interface IMentalHealthIndicators {
  stress: 'none' | 'mild' | 'moderate' | 'severe';
  anxiety: 'none' | 'mild' | 'moderate' | 'severe';
  depression: 'none' | 'mild' | 'moderate' | 'severe';
}

export interface IPersonalizedSettings {
  dailyCalorieGoal: number;
  dailyProteinGoalG: number;
  dailyCarbGoalG: number;
  dailyFatGoalG: number;
  dailyWaterGoalMl: number;
  dailyStepGoal: number;
  sleepGoalHours: number;
  reminderEnabled: boolean;
}

export interface IMealPreferences {
  avoidIngredients: string[];
  preferLowGI: boolean;
  preferLowSodium: boolean;
  preferLowFat: boolean;
  recommendedCuisines: string[];
}

export interface IDoctorPreference {
  specialty: string;
  priority: number;
  reason: string;
}

export interface IDoshaAlignment {
  dosha: string;
  aiConfirmed: boolean;
  reasoning: string;
}

export interface IInlineSuggestionConfig {
  // Meal warning rules
  mealTriggerKeywords: string[];          // e.g. ['sugar', 'refined carbs', 'high sodium']
  mealWarningTemplate: string;            // e.g. 'High {keyword} detected — not ideal for your diabetes.'
  // Glucose reading rules (for diabetic users)
  glucoseTargetMin: number;               // mg/dL — lower bound of healthy range
  glucoseTargetMax: number;               // mg/dL — upper bound of healthy range
  glucoseHighComment: string;             // shown when reading > max
  glucoseLowComment: string;              // shown when reading < min
  glucoseNormalComment: string;           // shown when reading is within range
}

export interface IStep5QA {
  questionId: string;
  questionText: string;
  answer: string | number | boolean;
}

// ── Main document interface ──────────────────────────────────────────────────

export interface IAIHealthProfile extends Document {
  userId: Types.ObjectId;
  analysisVersion: number;                // incremented on each re-analysis
  generatedAt: Date;
  provider: 'gemini' | 'groq' | 'formula'; // which system generated this
  status: 'pending' | 'complete' | 'error'; // tracks async job state
  isSerious: boolean;                     // true if ≥2 conditions OR any severity=severe
  conditions: ICondition[];
  riskFlags: string[];                    // e.g. ['prediabetes_risk', 'hypertension_risk']
  mentalHealthIndicators: IMentalHealthIndicators;
  personalizedSettings: IPersonalizedSettings;
  mealPreferences: IMealPreferences;
  doctorPreferences: IDoctorPreference[];
  doshaAlignment: IDoshaAlignment;
  weeklyInsights: string[];               // refreshed on lightweight re-analysis
  inlineSuggestionConfig: IInlineSuggestionConfig;
  step5Responses: IStep5QA[];            // raw Q&A from Step 5 (audit trail)
  rawAIOutput?: string;                   // raw JSON string from AI (for debugging)
  logEntrySinceLastAnalysis: number;      // counter — incremented on each log, reset on re-analysis
  createdAt: Date;
  updatedAt: Date;
}

// ── Schema ───────────────────────────────────────────────────────────────────

const conditionSchema = new Schema<ICondition>(
  {
    name: { type: String, required: true },
    severity: { type: String, enum: ['mild', 'moderate', 'severe'], required: true },
  },
  { _id: false }
);

const mentalHealthSchema = new Schema<IMentalHealthIndicators>(
  {
    stress: { type: String, enum: ['none', 'mild', 'moderate', 'severe'], default: 'none' },
    anxiety: { type: String, enum: ['none', 'mild', 'moderate', 'severe'], default: 'none' },
    depression: { type: String, enum: ['none', 'mild', 'moderate', 'severe'], default: 'none' },
  },
  { _id: false }
);

const personalizedSettingsSchema = new Schema<IPersonalizedSettings>(
  {
    dailyCalorieGoal: { type: Number, default: 2000 },
    dailyProteinGoalG: { type: Number, default: 100 },
    dailyCarbGoalG: { type: Number, default: 250 },
    dailyFatGoalG: { type: Number, default: 65 },
    dailyWaterGoalMl: { type: Number, default: 3000 },
    dailyStepGoal: { type: Number, default: 8000 },
    sleepGoalHours: { type: Number, default: 8 },
    reminderEnabled: { type: Boolean, default: false },
  },
  { _id: false }
);

const mealPreferencesSchema = new Schema<IMealPreferences>(
  {
    avoidIngredients: [{ type: String }],
    preferLowGI: { type: Boolean, default: false },
    preferLowSodium: { type: Boolean, default: false },
    preferLowFat: { type: Boolean, default: false },
    recommendedCuisines: [{ type: String }],
  },
  { _id: false }
);

const doctorPreferenceSchema = new Schema<IDoctorPreference>(
  {
    specialty: { type: String, required: true },
    priority: { type: Number, required: true },
    reason: { type: String, default: '' },
  },
  { _id: false }
);

const doshaAlignmentSchema = new Schema<IDoshaAlignment>(
  {
    dosha: { type: String, default: '' },
    aiConfirmed: { type: Boolean, default: false },
    reasoning: { type: String, default: '' },
  },
  { _id: false }
);

const inlineSuggestionConfigSchema = new Schema<IInlineSuggestionConfig>(
  {
    mealTriggerKeywords: [{ type: String }],
    mealWarningTemplate: { type: String, default: '' },
    glucoseTargetMin: { type: Number, default: 70 },
    glucoseTargetMax: { type: Number, default: 140 },
    glucoseHighComment: {
      type: String,
      default: 'Your reading is above your target range. Consider light movement like a short walk.',
    },
    glucoseLowComment: {
      type: String,
      default: 'Your reading is below target. Consider a small snack to stabilise your levels.',
    },
    glucoseNormalComment: {
      type: String,
      default: 'Great reading — within your target range. Keep it up!',
    },
  },
  { _id: false }
);

const step5QASchema = new Schema<IStep5QA>(
  {
    questionId: { type: String, required: true },
    questionText: { type: String, required: true },
    answer: { type: Schema.Types.Mixed, required: true },
  },
  { _id: false }
);

const aiHealthProfileSchema = new Schema<IAIHealthProfile>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'User ID is required'],
      unique: true,
    },
    analysisVersion: { type: Number, default: 0 },
    generatedAt: { type: Date, default: Date.now },
    provider: {
      type: String,
      enum: ['gemini', 'groq', 'formula'],
      default: 'formula',
    },
    status: {
      type: String,
      enum: ['pending', 'complete', 'error'],
      default: 'pending',
    },
    isSerious: { type: Boolean, default: false },
    conditions: [conditionSchema],
    riskFlags: [{ type: String }],
    mentalHealthIndicators: { type: mentalHealthSchema, default: () => ({}) },
    personalizedSettings: { type: personalizedSettingsSchema, default: () => ({}) },
    mealPreferences: { type: mealPreferencesSchema, default: () => ({}) },
    doctorPreferences: [doctorPreferenceSchema],
    doshaAlignment: { type: doshaAlignmentSchema, default: () => ({}) },
    weeklyInsights: [{ type: String }],
    inlineSuggestionConfig: { type: inlineSuggestionConfigSchema, default: () => ({}) },
    step5Responses: [step5QASchema],
    rawAIOutput: { type: String, select: false }, // hidden by default to reduce payload size
    logEntrySinceLastAnalysis: { type: Number, default: 0 },
  },
  { timestamps: true }
);

// ── Indexes ───────────────────────────────────────────────────────────────────
aiHealthProfileSchema.index({ userId: 1 }, { unique: true });
aiHealthProfileSchema.index({ status: 1 });
aiHealthProfileSchema.index({ generatedAt: -1 });

const AIHealthProfile = mongoose.model<IAIHealthProfile>('AIHealthProfile', aiHealthProfileSchema);
export default AIHealthProfile;
