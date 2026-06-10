import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.join(__dirname, '../../.env') });

interface Config {
  env: string;
  port: number;
  logLevel: string;
  
  // Database
  mongodb: {
    uri: string;
    dbName: string;
  };
  
  // Cache & Queue
  redis: {
    url: string;
  };
  
  // JWT
  jwt: {
    secret: string;
    refreshSecret: string;
    accessExpiry: string;
    refreshExpiry: string;
  };
  
  // OAuth
  google: {
    clientId: string;
    clientSecret: string;
    callbackUrl: string;
  };
  
  // AWS
  aws: {
    region: string;
    accessKeyId: string;
    secretAccessKey: string;
    s3Bucket: string;
  };
  
  // Payments (Razorpay)
  razorpay: {
    keyId: string;
    keySecret: string;
    webhookSecret: string;
  };
  
  // Firebase
  firebase: {
    projectId: string;
    privateKey: string;
    clientEmail: string;
    databaseUrl: string;
  };
  
  // Email & SMS
  email: {
    sendgridKey: string;
  };
  
  sms: {
    twilioAccountSid: string;
    twilioAuthToken: string;
    twilioPhoneNumber: string;
  };
  
  // Frontend
  frontend: {
    url: string;
  };
  
  // Error Tracking
  sentry: {
    dsn: string;
  };
}

export const config: Config = {
  env: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT || '3000', 10),
  logLevel: process.env.LOG_LEVEL || 'info',
  
  // Database
  mongodb: {
    uri: process.env.MONGODB_URI || 'mongodb://localhost:27017/healthx',
    dbName: process.env.MONGO_DB_NAME || 'healthx',
  },
  
  // Cache & Queue
  redis: {
    url: process.env.REDIS_URL || 'redis://localhost:6379',
  },
  
  // JWT
  jwt: {
    secret: process.env.JWT_SECRET || 'dev-jwt-secret-change-in-production',
    refreshSecret: process.env.JWT_REFRESH_SECRET || 'dev-refresh-secret-change-in-production',
    accessExpiry: process.env.JWT_EXPIRY || '30m',
    refreshExpiry: process.env.JWT_REFRESH_EXPIRY || '30d',
  },
  
  // OAuth
  google: {
    clientId: process.env.GOOGLE_CLIENT_ID || '',
    clientSecret: process.env.GOOGLE_CLIENT_SECRET || '',
    callbackUrl: process.env.GOOGLE_CALLBACK_URL || 'http://localhost:3000/auth/google/callback',
  },
  
  // AWS
  aws: {
    region: process.env.AWS_REGION || 'ap-south-1',
    accessKeyId: process.env.AWS_ACCESS_KEY_ID || '',
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || '',
    s3Bucket: process.env.AWS_S3_BUCKET || 'healthx-files',
  },
  
  // Payments (Razorpay)
  razorpay: {
    keyId: process.env.RAZORPAY_KEY_ID || '',
    keySecret: process.env.RAZORPAY_KEY_SECRET || '',
    webhookSecret: process.env.RAZORPAY_WEBHOOK_SECRET || '',
  },
  
  // Firebase
  firebase: {
    projectId: process.env.FIREBASE_PROJECT_ID || '',
    privateKey: process.env.FIREBASE_PRIVATE_KEY || '',
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL || '',
    databaseUrl: process.env.FIREBASE_DATABASE_URL || '',
  },
  
  // Email & SMS
  email: {
    sendgridKey: process.env.SENDGRID_API_KEY || '',
  },
  
  sms: {
    twilioAccountSid: process.env.TWILIO_ACCOUNT_SID || '',
    twilioAuthToken: process.env.TWILIO_AUTH_TOKEN || '',
    twilioPhoneNumber: process.env.TWILIO_PHONE_NUMBER || '',
  },
  
  // Frontend
  frontend: {
    url: process.env.FRONTEND_URL || 'http://localhost:8080',
  },
  
  // Error Tracking
  sentry: {
    dsn: process.env.SENTRY_DSN || '',
  },
};

// ─── Production secret validation ────────────────────────────────────────────
// Throw immediately on startup if running in production with insecure defaults
if (config.env === 'production') {
  const weakSecrets = [
    'dev-jwt-secret-change-in-production',
    'dev-refresh-secret-change-in-production',
    'your-super-secret-jwt-key-change-in-production',
    'your-super-secret-refresh-key-change-in-production',
    '',
  ];

  if (!config.jwt.secret || weakSecrets.includes(config.jwt.secret)) {
    throw new Error('[CONFIG] JWT_SECRET must be set to a strong, unique value in production!');
  }
  if (!config.jwt.refreshSecret || weakSecrets.includes(config.jwt.refreshSecret)) {
    throw new Error('[CONFIG] JWT_REFRESH_SECRET must be set to a strong, unique value in production!');
  }
  if (!process.env.MONGODB_URI) {
    throw new Error('[CONFIG] MONGODB_URI must be set in production!');
  }
  if (!config.google.clientId) {
    throw new Error('[CONFIG] GOOGLE_CLIENT_ID must be set in production for Google OAuth!');
  }
}