import mongoose, { Schema, Document } from 'mongoose';

export interface IMealPlan extends Document {
  planName: string;
  price: string;
  priceSuffix?: string;
  subtitle: string;
  badgeLabel?: string | null;
  accentColor: string;
  btnColor: string;
  isFeatured: boolean;
  tagIcon?: string;
  cardBgColor: string;
  assetImagePath: string;
  destination: string;
  createdAt: Date;
  updatedAt: Date;
}

const mealPlanSchema = new Schema<IMealPlan>(
  {
    planName: { type: String, required: true, trim: true },
    price: { type: String, required: true, trim: true },
    priceSuffix: { type: String, default: '' },
    subtitle: { type: String, required: true, trim: true },
    badgeLabel: { type: String, default: null },
    accentColor: { type: String, required: true },
    btnColor: { type: String, required: true },
    isFeatured: { type: Boolean, default: false },
    tagIcon: { type: String, default: '' },
    cardBgColor: { type: String, required: true },
    assetImagePath: { type: String, required: true },
    destination: { type: String, required: true },
  },
  { timestamps: true }
);

const MealPlan = mongoose.model<IMealPlan>('MealPlan', mealPlanSchema);
export default MealPlan;
