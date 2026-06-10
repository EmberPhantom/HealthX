import mongoose, { Schema, Document } from 'mongoose';

export interface IGlucoseLog extends Document {
  userId: mongoose.Types.ObjectId;
  level: number;           // mg/dL
  readingType: 'fasting' | 'post_meal' | 'random' | 'bedtime';
  note?: string;
  loggedAt: Date;
}

const glucoseLogSchema = new Schema<IGlucoseLog>(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    level: { type: Number, required: true },
    readingType: {
      type: String,
      enum: ['fasting', 'post_meal', 'random', 'bedtime'],
      required: true,
    },
    note: { type: String },
    loggedAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

glucoseLogSchema.index({ userId: 1, loggedAt: -1 });

const GlucoseLog = mongoose.model<IGlucoseLog>('GlucoseLog', glucoseLogSchema);
export default GlucoseLog;
