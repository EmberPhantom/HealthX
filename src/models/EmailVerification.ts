import mongoose, { Schema, Document } from 'mongoose';

export interface IEmailVerification extends Document {
  userId: mongoose.Types.ObjectId;
  email: string;
  token: string;
  expiresAt: Date;
  isVerified: boolean;
  verifiedAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

const emailVerificationSchema = new Schema<IEmailVerification>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true,
    },
    email: {
      type: String,
      required: true,
      lowercase: true,
      match: [/^[a-zA-Z0-9_.+-]+@\w+([.-]?\w+)*(\.\w{2,3})+$/, 'Invalid email format'],
    },
    token: {
      type: String,
      required: true,
      unique: true,
    },
    expiresAt: {
      type: Date,
      required: true,
      default: () => new Date(Date.now() + 24 * 60 * 60 * 1000), // 24 hours
      index: { expireAfterSeconds: 0 }, // Auto-delete after expiry
    },
    isVerified: {
      type: Boolean,
      default: false,
    },
    verifiedAt: {
      type: Date,
      default: null,
    },
  },
  { timestamps: true }
);

// Index for finding by token
emailVerificationSchema.index({ token: 1 });

// Index for finding by userId
emailVerificationSchema.index({ userId: 1 });

export default mongoose.model<IEmailVerification>('EmailVerification', emailVerificationSchema);
