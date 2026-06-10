import mongoose, { Schema, Document } from 'mongoose';

export interface IVitalsLog extends Document {
  userId: mongoose.Types.ObjectId;
  date: string;        // 'DD-MMM-YYYY' label
  time: string;        // 'HH:MM AM/PM'
  bp?: string;         // '120/80'
  pulse?: number;      // bpm
  temperature?: number; // °F
  weight?: number;     // kg
  spo2?: number;       // %
  exerciseMins?: number;
  loggedAt: Date;
}

const vitalsLogSchema = new Schema<IVitalsLog>(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    date: { type: String, required: true },
    time: { type: String, required: true },
    bp: { type: String },
    pulse: { type: Number },
    temperature: { type: Number },
    weight: { type: Number },
    spo2: { type: Number },
    exerciseMins: { type: Number },
    loggedAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

vitalsLogSchema.index({ userId: 1, loggedAt: -1 });

const VitalsLog = mongoose.model<IVitalsLog>('VitalsLog', vitalsLogSchema);
export default VitalsLog;
