import mongoose, { Schema, Document } from 'mongoose';

export interface IAuditLog extends Document {
  userId?: mongoose.Types.ObjectId;
  action: 'LOGIN' | 'LOGOUT' | 'SIGNUP' | 'PASSWORD_CHANGE' | 'PROFILE_UPDATE' | 'OAUTH_LOGIN' | 'FAILED_LOGIN' | 'ACCOUNT_LOCKED';
  resource: string;
  method: string;
  endpoint: string;
  status: number;
  ipAddress: string;
  userAgent: string;
  details?: Record<string, any>;
  success: boolean;
  errorMessage?: string;
  timestamp: Date;
  createdAt: Date;
}

const auditLogSchema = new Schema<IAuditLog>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      sparse: true,
      index: true,
    },
    action: {
      type: String,
      enum: ['LOGIN', 'LOGOUT', 'SIGNUP', 'PASSWORD_CHANGE', 'PROFILE_UPDATE', 'OAUTH_LOGIN', 'FAILED_LOGIN', 'ACCOUNT_LOCKED'],
      required: true,
      index: true,
    },
    resource: {
      type: String,
      required: true,
    },
    method: {
      type: String,
      enum: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
      required: true,
    },
    endpoint: {
      type: String,
      required: true,
    },
    status: {
      type: Number,
      required: true,
    },
    ipAddress: {
      type: String,
      required: true,
      index: true,
    },
    userAgent: {
      type: String,
      default: null,
    },
    details: {
      type: Schema.Types.Mixed,
      default: null,
    },
    success: {
      type: Boolean,
      required: true,
      index: true,
    },
    errorMessage: {
      type: String,
      default: null,
    },
    timestamp: {
      type: Date,
      default: Date.now,
      index: true,
    },
  },
  { timestamps: { createdAt: true, updatedAt: false } }
);

// Index for query efficiency
auditLogSchema.index({ userId: 1, action: 1, timestamp: -1 });
auditLogSchema.index({ ipAddress: 1, timestamp: -1 });
auditLogSchema.index({ action: 1, timestamp: -1 });

// TTL index: auto-delete audit logs after 90 days
auditLogSchema.index({ timestamp: 1 }, { expireAfterSeconds: 90 * 24 * 60 * 60 });

export default mongoose.model<IAuditLog>('AuditLog', auditLogSchema);
