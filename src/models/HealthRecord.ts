import mongoose, { Schema, Document } from 'mongoose';

export interface IHealthRecord extends Document {
  userId: mongoose.Types.ObjectId;
  name: string;
  type: 'labTests' | 'prescription' | 'scans' | 'other';
  date: Date;
  fileUrls: string[]; // URLs of uploaded files
  specialist: string; // e.g. 'Cardiologist', or empty string
  createdAt: Date;
  updatedAt: Date;
}

const healthRecordSchema = new Schema<IHealthRecord>(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    name: { type: String, required: true },
    type: {
      type: String,
      enum: ['labTests', 'prescription', 'scans', 'other'],
      required: true,
    },
    date: { type: Date, required: true },
    fileUrls: { type: [String], default: [] },
    specialist: { type: String, default: '' },
  },
  { timestamps: true }
);

healthRecordSchema.index({ userId: 1, date: -1, createdAt: -1 });

const HealthRecord = mongoose.model<IHealthRecord>('HealthRecord', healthRecordSchema);
export default HealthRecord;
