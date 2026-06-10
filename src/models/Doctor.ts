import mongoose, { Schema, Document } from 'mongoose';

export interface IDoctor extends Document {
  name: string;
  specialty: string;       // 'Diabetologist', 'Cardiologist', 'Nutritionist', etc.
  qualification: string;   // e.g. 'MBBS, MD, C.Diab'
  experience: number;      // years
  consultationFee: number; // ₹
  rating: number;
  reviewCount: number;
  avatarUrl?: string;
  clinicName: string;
  address: string;
  city: string;
  languages: string[];
  availableSlots: {
    day: string;           // 'Monday', 'Tuesday' etc.
    times: string[];       // ['09:00 AM', '09:30 AM', '10:00 AM', etc.]
  }[];
  isActive: boolean;
}

const doctorSchema = new Schema<IDoctor>(
  {
    name: { type: String, required: true },
    specialty: { type: String, required: true },
    qualification: { type: String, required: true },
    experience: { type: Number, required: true },
    consultationFee: { type: Number, required: true },
    rating: { type: Number, default: 5.0 },
    reviewCount: { type: Number, default: 0 },
    avatarUrl: { type: String },
    clinicName: { type: String, required: true },
    address: { type: String, required: true },
    city: { type: String, required: true },
    languages: { type: [String], default: [] },
    availableSlots: [
      {
        day: { type: String, required: true },
        times: { type: [String], required: true },
      },
    ],
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true }
);

doctorSchema.index({ specialty: 1, city: 1, isActive: 1 });

const Doctor = mongoose.model<IDoctor>('Doctor', doctorSchema);
export default Doctor;
