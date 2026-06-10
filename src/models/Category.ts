import mongoose, { Schema, Document } from 'mongoose';

export interface ICategory extends Document {
  name: string;
  emoji: string;
  createdAt: Date;
  updatedAt: Date;
}

const categorySchema = new Schema<ICategory>(
  {
    name: { type: String, required: true, unique: true, trim: true },
    emoji: { type: String, required: true },
  },
  { timestamps: true }
);

const Category = mongoose.model<ICategory>('Category', categorySchema);
export default Category;
