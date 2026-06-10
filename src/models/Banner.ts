import mongoose, { Schema, Document } from 'mongoose';

export interface IBanner extends Document {
  imagePath: string;
  title: string;
  subtitle: string;
  chipLabel: string;
  createdAt: Date;
  updatedAt: Date;
}

const bannerSchema = new Schema<IBanner>(
  {
    imagePath: { type: String, required: true },
    title: { type: String, required: true },
    subtitle: { type: String, required: true },
    chipLabel: { type: String, required: true },
  },
  { timestamps: true }
);

const Banner = mongoose.model<IBanner>('Banner', bannerSchema);
export default Banner;
