import mongoose, { Schema, Document } from 'mongoose';

export interface IAppointment extends Document {
  userId: mongoose.Types.ObjectId;
  doctorId: mongoose.Types.ObjectId;
  appointmentDate: Date;
  timeSlot: string;        // e.g. '10:00 AM'
  type: 'in-person' | 'video';
  status: 'pending' | 'confirmed' | 'cancelled' | 'completed';
  symptoms?: string;
  notes?: string;
  consultationFee: number;
  isPaid: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const appointmentSchema = new Schema<IAppointment>(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    doctorId: { type: Schema.Types.ObjectId, ref: 'Doctor', required: true },
    appointmentDate: { type: Date, required: true },
    timeSlot: { type: String, required: true },
    type: { type: String, enum: ['in-person', 'video'], default: 'in-person' },
    status: {
      type: String,
      enum: ['pending', 'confirmed', 'cancelled', 'completed'],
      default: 'pending',
    },
    symptoms: { type: String },
    notes: { type: String },
    consultationFee: { type: Number, required: true },
    isPaid: { type: Boolean, default: false },
  },
  { timestamps: true }
);

appointmentSchema.index({ userId: 1, appointmentDate: -1 });
appointmentSchema.index({ doctorId: 1, appointmentDate: -1 });

const Appointment = mongoose.model<IAppointment>('Appointment', appointmentSchema);
export default Appointment;
