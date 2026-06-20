import mongoose, { Schema, Document } from 'mongoose';

export interface IMenuItem extends Document {
  name: string;
  description: string;
  price: number;
  calories: number;
  rating: number;
  reviewCount: number;
  imageUrl: string;
  emoji: string;
  category: string;
  type: 'Regular' | 'ReadyToEat';
  tags: string[];
  isVeg: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const menuItemSchema = new Schema<IMenuItem>(
  {
    name: { type: String, required: true, trim: true },
    description: { type: String, required: true, trim: true },
    price: { type: Number, required: true },
    calories: { type: Number, required: true },
    rating: { type: Number, default: 5.0 },
    reviewCount: { type: Number, default: 0 },
    imageUrl: { type: String, default: '' },
    emoji: { type: String, default: '🥗' },
    category: { type: String, required: true, trim: true },
    type: {
      type: String,
      enum: ['Regular', 'ReadyToEat'],
      default: 'Regular'
    },
    tags: { type: [String], default: [] },
    isVeg: { type: Boolean, default: true },
  },
  { timestamps: true }
);

menuItemSchema.index({ category: 1 });

const MenuItem = mongoose.model<IMenuItem>('MenuItem', menuItemSchema);
export default MenuItem;
