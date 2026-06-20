import mongoose, { Schema, Document } from 'mongoose';

export interface IPrescribedMedication {
  name: string;
  dosage: string;
  frequency: string;
  duration?: string;
}

export interface IPrescription extends Document {
  appointmentId: mongoose.Types.ObjectId;
  doctorId: mongoose.Types.ObjectId;
  userId: mongoose.Types.ObjectId;
  doctorNotes?: string;
  medications: IPrescribedMedication[];
  issuedAt: Date;
  createdAt: Date;
  updatedAt: Date;
}

const prescribedMedicationSchema = new Schema<IPrescribedMedication>({
  name: { type: String, required: true },
  dosage: { type: String, required: true },
  frequency: { type: String, required: true },
  duration: { type: String },
});

const prescriptionSchema = new Schema<IPrescription>(
  {
    appointmentId: { type: Schema.Types.ObjectId, ref: 'Appointment', required: true, unique: true },
    doctorId: { type: Schema.Types.ObjectId, ref: 'Doctor', required: true },
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    doctorNotes: { type: String },
    medications: { type: [prescribedMedicationSchema], default: [] },
    issuedAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

prescriptionSchema.index({ appointmentId: 1 });
prescriptionSchema.index({ userId: 1, issuedAt: -1 });

const Prescription = mongoose.model<IPrescription>('Prescription', prescriptionSchema);
export default Prescription;
