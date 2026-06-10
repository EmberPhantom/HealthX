import mongoose, { Schema, Document } from 'mongoose';

export interface IStepLog extends Document {
  userId: mongoose.Types.ObjectId;
  steps: number;
  dateKey: string; // YYYY-MM-DD
}

const stepLogSchema = new Schema<IStepLog>(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    steps: { type: Number, required: true },
    dateKey: { type: String, required: true },
  },
  { timestamps: true }
);

stepLogSchema.index({ userId: 1, dateKey: 1 }, { unique: true });

const StepLog = mongoose.model<IStepLog>('StepLog', stepLogSchema);
export default StepLog;
