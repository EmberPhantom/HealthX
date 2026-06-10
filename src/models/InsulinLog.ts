import mongoose, { Schema, Document } from 'mongoose';

export interface IInsulinLog extends Document {
  userId: mongoose.Types.ObjectId;
  dose: number;            // units
  insulinType: string;     // 'Rapid-acting', 'Long-acting', etc.
  injectionSite?: string;
  mealContext?: 'before_meal' | 'after_meal' | 'bedtime';
  note?: string;
  loggedAt: Date;
}

const insulinLogSchema = new Schema<IInsulinLog>(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    dose: { type: Number, required: true },
    insulinType: { type: String, required: true },
    injectionSite: { type: String },
    mealContext: {
      type: String,
      enum: ['before_meal', 'after_meal', 'bedtime'],
    },
    note: { type: String },
    loggedAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

insulinLogSchema.index({ userId: 1, loggedAt: -1 });

const InsulinLog = mongoose.model<IInsulinLog>('InsulinLog', insulinLogSchema);
export default InsulinLog;
