import mongoose, { Schema, Document } from 'mongoose';

export interface IWaterLog extends Document {
  userId: mongoose.Types.ObjectId;
  amount: number; // in ml
  loggedAt: Date;
}

const waterLogSchema = new Schema<IWaterLog>(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    amount: { type: Number, required: true },
    loggedAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

waterLogSchema.index({ userId: 1, loggedAt: -1 });

const WaterLog = mongoose.model<IWaterLog>('WaterLog', waterLogSchema);
export default WaterLog;
