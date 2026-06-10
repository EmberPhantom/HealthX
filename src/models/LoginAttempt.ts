import mongoose, { Schema, Document } from 'mongoose';

export interface ILoginAttempt extends Document {
  userId?: mongoose.Types.ObjectId;
  email: string;
  ipAddress: string;
  success: boolean;
  userAgent?: string;
  attemptedAt: Date;
  isBlocked: boolean;
  blockedUntil?: Date;
  consecutiveFailures: number;
  createdAt: Date;
  updatedAt: Date;
}

const loginAttemptSchema = new Schema<ILoginAttempt>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      sparse: true,
      index: true,
    },
    email: {
      type: String,
      required: true,
      lowercase: true,
      index: true,
    },
    ipAddress: {
      type: String,
      required: true,
      index: true,
    },
    success: {
      type: Boolean,
      default: false,
    },
    userAgent: {
      type: String,
      default: null,
    },
    attemptedAt: {
      type: Date,
      default: Date.now,
      index: true,
    },
    isBlocked: {
      type: Boolean,
      default: false,
      index: true,
    },
    blockedUntil: {
      type: Date,
      default: null,
      index: true,
      sparse: true,
    },
    consecutiveFailures: {
      type: Number,
      default: 0,
    },
  },
  { timestamps: true }
);

// Index for finding recent failed attempts
loginAttemptSchema.index({ email: 1, success: 1, attemptedAt: -1 });
loginAttemptSchema.index({ ipAddress: 1, success: 1, attemptedAt: -1 });

// TTL index - auto-delete attempts older than 7 days
loginAttemptSchema.index({ createdAt: 1 }, { expireAfterSeconds: 7 * 24 * 60 * 60 });

export default mongoose.model<ILoginAttempt>('LoginAttempt', loginAttemptSchema);
