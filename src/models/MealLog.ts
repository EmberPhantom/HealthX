import mongoose, { Schema, Document } from 'mongoose';

export interface IMealLog extends Document {
  userId: mongoose.Types.ObjectId;
  mealType: 'Breakfast' | 'Lunch' | 'Dinner' | 'Snack';
  foodName: string;
  calories: number;
  protein: number;
  fat: number;
  carbs: number;
  imageUrl?: string;
  ingredients: string[];
  loggedAt: Date;
}

const mealLogSchema = new Schema<IMealLog>(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    mealType: {
      type: String,
      enum: ['Breakfast', 'Lunch', 'Dinner', 'Snack'],
      required: true
    },
    foodName: { type: String, required: true },
    calories: { type: Number, required: true },
    protein: { type: Number, required: true },
    fat: { type: Number, required: true },
    carbs: { type: Number, required: true },
    imageUrl: { type: String },
    ingredients: { type: [String], default: [] },
    loggedAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

mealLogSchema.index({ userId: 1, loggedAt: -1 });

const MealLog = mongoose.model<IMealLog>('MealLog', mealLogSchema);
export default MealLog;
