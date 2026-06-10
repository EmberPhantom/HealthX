import mongoose, { Schema, Document } from 'mongoose';

export interface IMeasurementLog extends Document {
  userId: mongoose.Types.ObjectId;
  weight?: number;     // kg
  height?: number;     // cm
  bmi?: number;        // computed server-side
  chest?: number;      // cm
  waist?: number;      // cm
  hips?: number;       // cm
  bodyFatPercent?: number;
  loggedAt: Date;
}

const measurementLogSchema = new Schema<IMeasurementLog>(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    weight: { type: Number },
    height: { type: Number },
    bmi: { type: Number },
    chest: { type: Number },
    waist: { type: Number },
    hips: { type: Number },
    bodyFatPercent: { type: Number },
    loggedAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

measurementLogSchema.index({ userId: 1, loggedAt: -1 });

const MeasurementLog = mongoose.model<IMeasurementLog>('MeasurementLog', measurementLogSchema);
export default MeasurementLog;
