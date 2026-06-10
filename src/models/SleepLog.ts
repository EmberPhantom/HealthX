import mongoose, { Schema, Document } from 'mongoose';

export interface ISleepLog extends Document {
  userId: mongoose.Types.ObjectId;
  bedtime: Date;
  wakeTime: Date;
  dateKey: string; // YYYY-MM-DD
}

const sleepLogSchema = new Schema<ISleepLog>(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    bedtime: { type: Date, required: true },
    wakeTime: { type: Date, required: true },
    dateKey: { type: String, required: true },
  },
  { timestamps: true }
);

sleepLogSchema.index({ userId: 1, dateKey: 1 }, { unique: true });

const SleepLog = mongoose.model<ISleepLog>('SleepLog', sleepLogSchema);
export default SleepLog;
