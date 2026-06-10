import mongoose, { Schema, Document, Types } from 'mongoose';

export interface IPatient extends Document {
  userId: Types.ObjectId;
  medicalHistory?: string;
  allergies: string[];
  medications: string[];
  emergencyContact?: {
    name: string;
    phone: string;
    relation: string;
  };
  insuranceProvider?: string;
  insurancePolicyNo?: string;
  height?: number;
  weight?: number;
  isDiabetesPatient?: boolean;
  isBpPatient?: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const patientSchema = new Schema<IPatient>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'User ID is required'],
      unique: true,
    },
    medicalHistory: {
      type: String,
    },
    allergies: {
      type: [String],
      default: [],
    },
    medications: {
      type: [String],
      default: [],
    },
    emergencyContact: {
      type: {
        name: String,
        phone: String,
        relation: String,
      },
    },
    insuranceProvider: {
      type: String,
    },
    insurancePolicyNo: {
      type: String,
    },
    height: {
      type: Number,
    },
    weight: {
      type: Number,
    },
    isDiabetesPatient: {
      type: Boolean,
      default: false,
    },
    isBpPatient: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

// Indexes
patientSchema.index({ userId: 1 });

const Patient = mongoose.model<IPatient>('Patient', patientSchema);

export default Patient;
