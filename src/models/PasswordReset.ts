import mongoose, { Schema, Document } from 'mongoose';

export interface IPasswordReset extends Document {
  userId: mongoose.Types.ObjectId;
  email: string;
  token: string;
  expiresAt: Date;
  usedAt?: Date;
  isUsed: boolean;
}

const passwordResetSchema = new Schema<IPasswordReset>({
  userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  email: { type: String, required: true },
  token: { type: String, required: true, unique: true },
  expiresAt: { type: Date, required: true },
  usedAt: { type: Date },
  isUsed: { type: Boolean, default: false },
}, { timestamps: true });

// TTL index: delete expired documents when expiresAt is reached
passwordResetSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });
passwordResetSchema.index({ token: 1 }, { unique: true });

export default mongoose.model<IPasswordReset>('PasswordReset', passwordResetSchema);
