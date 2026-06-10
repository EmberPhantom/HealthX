import mongoose, { Schema, Document } from 'mongoose';
import bcryptjs from 'bcryptjs';

export interface IUser extends Document {
  email: string;
  password?: string;
  // Google OAuth only
  googleId?: string;
  googleRefreshToken?: string;
  name: string;
  phone?: string;      // Optional — Google OAuth users may not have phone
  gender?: 'Male' | 'Female' | 'Others';
  age?: number;
  avatarUrl?: string;
  role: 'user' | 'admin' | 'provider';
  isEmailVerified: boolean;
  isActive: boolean;
  onboardingComplete: boolean;
  favorites: mongoose.Types.ObjectId[];
  wellnessGoals: string[];
  dominantDosha?: 'Vata' | 'Pitta' | 'Kapha' | 'Vata-Pitta' | 'Pitta-Kapha' | 'Vata-Kapha' | 'Tridoshic';
  appRating?: number;
  points: number;
  settings?: {
    dailyWaterGoalMl: number;
    dailyStepGoal: number;
    reminderEnabled: boolean;
  };
  createdAt: Date;
  updatedAt: Date;
  comparePassword(candidatePassword: string): Promise<boolean>;
}

const userSchema = new Schema<IUser>(
  {
    email: {
      type: String,
      required: [true, 'Email is required'],
      unique: true,
      trim: true,
      match: [
        /^[a-zA-Z0-9_.+-]+@\w+([\.-]?\w+)*(\.\w{2,3})+$/,
        'Please provide a valid email',
      ],
    },
    password: {
      type: String,
      select: false,
      minlength: 8,
    },
    // Google OAuth fields
    googleId: {
      type: String,
      sparse: true,
      unique: true,
    },
    googleRefreshToken: {
      type: String,
      select: false,
    },
    name: {
      type: String,
      required: [true, 'Name is required'],
      trim: true,
    },
    phone: {
      type: String,
      required: [
        function(this: any) {
          return !this.googleId;
        },
        'Phone number is required',
      ],
      trim: true,
    },
    gender: {
      type: String,
      enum: ['Male', 'Female', 'Others'],
      default: undefined,
    },
    age: {
      type: Number,
      min: 18,
      max: 120,
    },
    avatarUrl: {
      type: String,
    },
    role: {
      type: String,
      enum: ['user', 'admin', 'provider'],
      default: 'user',
    },
    isEmailVerified: {
      type: Boolean,
      default: false,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    onboardingComplete: {
      type: Boolean,
      default: false,
    },
    favorites: [{
      type: Schema.Types.ObjectId,
      ref: 'MenuItem',
    }],
    wellnessGoals: [{
      type: String,
    }],
    dominantDosha: {
      type: String,
      enum: ['Vata', 'Pitta', 'Kapha', 'Vata-Pitta', 'Pitta-Kapha', 'Vata-Kapha', 'Tridoshic'],
    },
    appRating: {
      type: Number,
      min: 1,
      max: 5,
    },
    points: {
      type: Number,
      default: 0,
    },
    settings: {
      dailyWaterGoalMl: { type: Number, default: 3000 },
      dailyStepGoal: { type: Number, default: 8000 },
      reminderEnabled: { type: Boolean, default: false },
    },
  },
  {
    timestamps: true,
  }
);

// Indexes for query performance
userSchema.index({ email: 1 }, { unique: true });
userSchema.index({ googleId: 1 }, { unique: true, sparse: true });
userSchema.index({ createdAt: -1 });
userSchema.index({ role: 1 });

// Hash password before saving (only if modified)
userSchema.pre('save', async function (this: any, next: any) {
  if (!this.isModified('password') || !this.password) {
    return next();
  }

  try {
    const salt = await bcryptjs.genSalt(10);
    this.password = await bcryptjs.hash(this.password, salt);
    next();
  } catch (error) {
    next(error instanceof Error ? error : new Error(String(error)));
  }
});

// Compare password method
userSchema.methods.comparePassword = async function (
  candidatePassword: string
): Promise<boolean> {
  if (!this.password) return false;
  return await bcryptjs.compare(candidatePassword, this.password);
};

// Create the model
const User = mongoose.model<IUser>('User', userSchema);

export default User;
