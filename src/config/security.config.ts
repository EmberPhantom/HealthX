/**
 * Security configuration for Phase 2
 */

export const securityConfig = {
  // CSRF Protection
  csrf: {
    enabled: true,
    tokenExpiry: 30 * 60 * 1000, // 30 minutes
    storageType: 'memory', // 'memory' or 'redis'
  },

  // Rate Limiting
  rateLimit: {
    enabled: true,
    // Auth endpoints (login, signup)
    auth: {
      windowMinutes: 15,
      maxRequests: 5, // 5 attempts per 15 minutes
    },
    // API general endpoints
    api: {
      windowMinutes: 15,
      maxRequests: 100, // 100 requests per 15 minutes
    },
    // Sensitive operations (password change, account deletion)
    sensitive: {
      windowMinutes: 30,
      maxRequests: 3, // 3 attempts per 30 minutes
    },
  },

  // Account Lockout
  accountLockout: {
    enabled: true,
    maxFailedAttempts: 5, // Lock after 5 failed attempts
    lockoutDurationMinutes: 15, // Lock for 15 minutes
    resetCounterAfterMinutes: 30, // Reset counter after 30 minutes of no attempts
  },

  // Login Tracking
  loginTracking: {
    enabled: true,
    trackFailedAttempts: true,
    trackSuccessfulLogins: true,
    retentionDays: 7, // Keep login history for 7 days
  },

  // Audit Logging
  auditLog: {
    enabled: true,
    logActions: [
      'LOGIN',
      'LOGOUT',
      'SIGNUP',
      'PASSWORD_CHANGE',
      'PROFILE_UPDATE',
      'OAUTH_LOGIN',
      'FAILED_LOGIN',
      'ACCOUNT_LOCKED',
    ],
    retentionDays: 90, // Keep audit logs for 90 days
  },

  // IP-based Security
  ipSecurity: {
    enabled: true,
    trackIPs: true,
    blockSuspiciousIPs: true,
    suspiciousThreshold: 10, // Failed attempts from IP in 1 hour
    blockDurationMinutes: 30,
    whitelist: process.env.IP_WHITELIST?.split(',') || [
      '127.0.0.1',
      '::1',
      'localhost',
    ],
  },

  // Password Security
  password: {
    minLength: 8,
    requireUppercase: true,
    requireNumbers: true,
    requireSpecialChars: true,
    hashRounds: 10, // bcryptjs rounds
  },

  // Session Security
  session: {
    cookieSecure: process.env.NODE_ENV === 'production',
    cookieHttpOnly: true,
    cookieSameSite: 'strict' as const,
    sessionTimeout: 30 * 60 * 1000, // 30 minutes
  },

  // OAuth Security
  oauth: {
    enabled: true,
    providers: ['google', 'github', 'microsoft'],
    stateExpirySeconds: 600, // 10 minutes
  },

  // HTTPS/TLS
  https: {
    enforceHTTPS: process.env.NODE_ENV === 'production',
    hstsMaxAge: 31536000, // 1 year
    hstsIncludeSubdomains: true,
    hstsPreload: true,
  },

  // CORS
  cors: {
    origins: (process.env.CORS_ORIGINS || 'http://localhost:3000').split(','),
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: [
      'Content-Type',
      'Authorization',
      'X-CSRF-Token',
      'X-Requested-With',
    ],
  },

  // Content Security Policy
  csp: {
    enabled: true,
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "'unsafe-inline'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", 'data:', 'https:'],
      connectSrc: ["'self'"],
      fontSrc: ["'self'"],
      objectSrc: ["'none'"],
      mediaSrc: ["'self'"],
      frameSrc: ["'self'"],
    },
  },

  // Security Headers
  headers: {
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'SAMEORIGIN',
    'X-XSS-Protection': '1; mode=block',
    'Strict-Transport-Security': 'max-age=31536000; includeSubDomains; preload',
    'Referrer-Policy': 'strict-origin-when-cross-origin',
    'Permissions-Policy': 'geolocation=(), microphone=(), camera=()',
  },
};

export default securityConfig;
