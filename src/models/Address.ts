import mongoose, { Schema, Document } from 'mongoose';

export interface IAddress extends Document {
  userId: mongoose.Types.ObjectId;
  label: string;         // 'Home', 'Work', 'Other'
  street: string;
  area: string;
  city: string;
  pincode: string;
  isDefault: boolean;
  latitude?: number;
  longitude?: number;
  createdAt: Date;
}

const addressSchema = new Schema<IAddress>(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    label: { type: String, required: true },
    street: { type: String, required: true },
    area: { type: String, required: true },
    city: { type: String, required: true },
    pincode: { type: String, required: true },
    isDefault: { type: Boolean, default: false },
    latitude: { type: Number },
    longitude: { type: Number },
  },
  { timestamps: true }
);

addressSchema.index({ userId: 1, isDefault: -1 });

const Address = mongoose.model<IAddress>('Address', addressSchema);
export default Address;
