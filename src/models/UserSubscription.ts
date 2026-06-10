import mongoose, { Schema, Document } from 'mongoose';

export interface IUserSubscription extends Document {
  userId: mongoose.Types.ObjectId;
  planId: mongoose.Types.ObjectId;
  planName: string;
  status: 'active' | 'paused' | 'cancelled' | 'expired';
  price: string;
  startDate: Date;
  endDate: Date;
  billingPeriod: 'monthly' | 'weekly';
  createdAt: Date;
  updatedAt: Date;
}

const userSubscriptionSchema = new Schema<IUserSubscription>(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    planId: { type: Schema.Types.ObjectId, ref: 'MealPlan', required: true },
    planName: { type: String, required: true },
    status: {
      type: String,
      enum: ['active', 'paused', 'cancelled', 'expired'],
      default: 'active',
      index: true
    },
    price: { type: String, required: true },
    startDate: { type: Date, default: Date.now },
    endDate: { type: Date, required: true },
    billingPeriod: {
      type: String,
      enum: ['monthly', 'weekly'],
      default: 'monthly'
    }
  },
  { timestamps: true }
);

const UserSubscription = mongoose.model<IUserSubscription>('UserSubscription', userSubscriptionSchema);
export default UserSubscription;
