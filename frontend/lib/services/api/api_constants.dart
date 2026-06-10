/// API Constants and Configuration
/// Defines all backend endpoints, base URLs, and timeout values

import 'package:flutter/foundation.dart';

// ============================================================================
// API ENVIRONMENT CONFIGURATION
// ============================================================================

enum ApiEnvironment {
  development,
  staging,
  production,
}

/// Current environment — change to production before release
const ApiEnvironment currentEnvironment = ApiEnvironment.development;

class ApiConfig {
  static const Map<ApiEnvironment, String> baseUrls = {
    ApiEnvironment.staging: 'https://staging-api.healthx.com',
    ApiEnvironment.production: 'https://api.healthx.com',
    // Development URL is resolved dynamically at runtime (see baseUrl getter)
    ApiEnvironment.development: 'http://localhost:3000',
  };

  /// The host passed via --dart-define=DEV_HOST=<machine-ip>
  /// Use scripts/run_dev.ps1 which auto-detects the LAN IP.
  /// Falls back to localhost for web/CI environments.
  static const String _devHost =
      String.fromEnvironment('DEV_HOST', defaultValue: '');

  static String get baseUrl {
    if (currentEnvironment == ApiEnvironment.development) {
      if (kIsWeb) return 'http://localhost:3000';

      // 1. Prioritize DEV_HOST from --dart-define=DEV_HOST=192.168.x.x
      if (_devHost.isNotEmpty) {
        return 'http://$_devHost:3000';
      }

      // 2. Fallback for physical devices: 
      // Replace this with your computer's IP address (e.g., '192.168.1.5') 
      // if you are debugging on a physical phone.
      const String manualIp = ''; // <-- SET YOUR IP HERE for physical device
      if (manualIp.isNotEmpty) {
        return 'http://$manualIp:3000';
      }

      // 3. Fallback for Android Emulators
      try {
        if (defaultTargetPlatform == TargetPlatform.android) {
          // Note: This ONLY works on emulators. 
          // Physical devices will timeout on this address.
          return 'http://10.0.2.2:3000';
        }
      } catch (_) {}

      return 'http://localhost:3000';
    }
    return baseUrls[currentEnvironment] ?? 'http://localhost:3000';
  }

  static const String apiVersion = '/api/v1';
  static String get apiBasePath => '$baseUrl$apiVersion';

  static const int requestTimeoutSeconds = 30;
  /// Increased from 10s → 20s:
  /// - Mobile hotspot networks can be slow on first connect
  /// - POST /auth/google requires the backend to call Google's verification
  ///   servers, adding ~2–5s of upstream latency on top of the local hop
  static const int connectionTimeoutSeconds = 20;
  static const int receiveTimeoutSeconds = 30;

  /// Only log in debug builds — prevents token/data leakage in production
  static bool get enableLogging => kDebugMode;
  static bool get enableDebugLogging => kDebugMode;
}

// ============================================================================
// AUTHENTICATION ENDPOINTS
// ============================================================================

class AuthEndpoints {
  /// POST /auth/signup
  /// Body: { name, email, password, phone? }
  static const String signup = '/auth/signup';

  /// POST /auth/login
  /// Body: { email, password }
  static const String login = '/auth/login';

  /// POST /auth/logout
  /// Headers: { Authorization: Bearer token }
  /// Body: { refreshToken }
  static const String logout = '/auth/logout';

  /// POST /auth/refresh
  /// Body: { refreshToken }
  static const String refreshToken = '/auth/refresh';

  /// POST /auth/google
  /// Body: { idToken } — Google ID token from google_sign_in + firebase_auth
  static const String googleAuth = '/auth/google';

  /// GET /auth/me — Get current user profile
  static const String getMe = '/auth/me';

  /// PUT /auth/me — Update current user profile
  static const String updateMe = '/auth/me';

  /// POST /auth/me/upload-picture
  /// Body: FormData with file field named 'file'
  static const String uploadProfilePicture = '/auth/me/upload-picture';

  /// POST /auth/link — Link Google to account
  static const String linkOAuthProvider = '/auth/link';

  /// POST /auth/unlink — Unlink Google from account
  static const String unlinkOAuthProvider = '/auth/unlink';
}

// ============================================================================
// ONBOARDING ENDPOINTS
// ============================================================================

class OnboardingEndpoints {
  /// POST /onboarding/verify-email
  /// Body: { token }
  static const String verifyEmail = '/onboarding/verify-email';

  /// POST /onboarding/resend-verification
  /// Headers: { Authorization: Bearer token }
  static const String resendVerification = '/onboarding/resend-verification';

  /// POST /onboarding/complete
  /// Headers: { Authorization: Bearer token }
  static const String completeOnboarding = '/onboarding/complete';

  /// GET /onboarding/status
  /// Headers: { Authorization: Bearer token }
  static const String onboardingStatus = '/onboarding/status';
}

// ============================================================================
// USER ENDPOINTS
// ============================================================================

class UserEndpoints {
  /// GET /users/me — Get current user profile (FIXED: was /user/profile)
  static const String getProfile = '/users/me';

  /// PUT /users/me — Update user profile (FIXED: was /user/profile)
  static const String updateProfile = '/users/me';
  
  /// GET /users/me/stats — Get user profile stats
  static const String getStats = '/users/me/stats';

  /// GET /users/me/settings
  static const String getSettings = '/users/me/settings';

  /// PUT /users/me/settings
  static const String updateSettings = '/users/me/settings';

  /// POST /users/me/favorites/toggle
  static const String toggleFavorite = '/users/me/favorites/toggle';

  /// PUT /users/me/wellness-goals
  static const String updateWellnessGoals = '/users/me/wellness-goals';

  /// POST /users/me/rating
  static const String setRating = '/users/me/rating';

  /// PATCH /users/me/points
  static const String updatePoints = '/users/me/points';
}

// ============================================================================
// SECURITY ENDPOINTS
// ============================================================================

class SecurityEndpoints {
  /// POST /security/csrf-token
  static const String getCsrfToken = '/security/csrf-token';

  /// GET /security/login-history
  static const String getLoginHistory = '/security/login-history';

  /// GET /security/suspicious-activity
  static const String getSuspiciousActivity = '/security/suspicious-activity';

  /// POST /security/clear-failed-attempts
  static const String clearFailedAttempts = '/security/clear-failed-attempts';

  /// GET /security/audit-logs
  static const String getAuditLogs = '/security/audit-logs';
}

// ============================================================================
// ERROR CODES
// ============================================================================

class ErrorCodes {
  static const int invalidCredentials = 401;
  static const int tokenExpired = 401;
  static const int unauthorized = 403;
  static const int validationError = 400;
  static const int fieldValidationError = 422;
  static const int userNotFound = 404;
  static const int userAlreadyExists = 409;
  static const int emailAlreadyVerified = 409;
  static const int rateLimitExceeded = 429;
  static const int internalServerError = 500;
  static const int serviceUnavailable = 503;
  static const int networkTimeout = 0;
  static const int noConnection = -1;
}

// ============================================================================
// ERROR MESSAGES
// ============================================================================

class ErrorMessages {
  static const String invalidEmail = 'Invalid email address';
  static const String invalidPassword = 'Password must be at least 8 characters';
  static const String weakPassword = 'Password is too weak';
  static const String passwordMismatch = 'Passwords do not match';
  static const String userNotFound = 'User not found';
  static const String invalidCredentials = 'Invalid email or password';
  static const String tokenExpired = 'Session expired. Please login again.';
  static const String unauthorized =
      'You do not have permission to perform this action';
  static const String emailAlreadyVerified = 'Email is already verified';
  static const String invalidVerificationToken =
      'Invalid or expired verification token';
  static const String verificationTokenExpired =
      'Verification token has expired. Please request a new one.';
  static const String userAlreadyExists =
      'User with this email already exists';
  static const String failedToUpdateProfile =
      'Failed to update profile. Please try again.';
  static const String fileTooLarge = 'File is too large. Maximum size is 2MB.';
  static const String invalidFileType = 'File type not supported';
  static const String uploadFailed =
      'Failed to upload file. Please try again.';
  static const String rateLimitExceeded =
      'Too many requests. Please wait before trying again.';
  static const String loginRateLimitExceeded =
      'Too many login attempts. Please try again later.';
  static const String noConnection = 'No internet connection';
  static const String networkTimeout =
      'Request timed out. Please check your connection.';
  static const String serverError = 'Server error. Please try again later.';
  static const String somethingWentWrong =
      'Something went wrong. Please try again.';
  static const String unknownError = 'An unknown error occurred';
}

// ============================================================================
// REQUEST/RESPONSE HEADERS
// ============================================================================

class ApiHeaders {
  static const String contentType = 'Content-Type';
  static const String contentTypeJson = 'application/json';
  static const String authorization = 'Authorization';
  static const String authorizationBearer = 'Bearer';
  static const String userAgent = 'User-Agent';
  static const String xForwardedFor = 'X-Forwarded-For';
  static const String rateLimitLimit = 'X-RateLimit-Limit';
  static const String rateLimitRemaining = 'X-RateLimit-Remaining';
  static const String rateLimitReset = 'X-RateLimit-Reset';
  static const String retryAfter = 'Retry-After';
}

// ============================================================================
// VALIDATION CONSTRAINTS
// ============================================================================

class ValidationConstraints {
  static const int emailMinLength = 5;
  static const int emailMaxLength = 255;
  static const int passwordMinLength = 8;
  static const int passwordMaxLength = 128;
  static const int nameMinLength = 2;
  static const int nameMaxLength = 100;
  static const int phoneMinLength = 10;
  static const int phoneMaxLength = 20;
  static const int avatarMaxSizeBytes = 2 * 1024 * 1024; // 2MB
  static const int documentMaxSizeBytes = 10 * 1024 * 1024; // 10MB
  static const List<String> avatarMimeTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
  ];
  static const List<String> documentMimeTypes = [
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  ];
}

// ============================================================================
// TOKEN CONFIGURATION
// ============================================================================

class TokenConfig {
  static const int accessTokenExpiryMinutes = 30;
  static const int refreshTokenExpiryDays = 30;
  static const int refreshTokenThresholdMinutes = 5;
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String lastRefreshTimeKey = 'last_refresh_time';
}

class ContentEndpoints {
  static const String categories = '/content/categories';
  static const String banners = '/content/banners';
  static const String mealPlans = '/content/meal-plans';
  static const String menuItems = '/content/menu-items';
}

class MealEndpoints {
  static const String identify = '/meals/identify';
  static const String identifyImage = '/meals/identify-image';
  static const String log = '/meals/log';
  static const String getMeals = '/meals';
  static String delete(String id) => '/meals/$id';
}

class TrackerEndpoints {
  static const String logWater = '/trackers/water';
  static const String getWater = '/trackers/water';
  static const String logSleep = '/trackers/sleep';
  static const String getSleep = '/trackers/sleep';
  static const String logSteps = '/trackers/steps';
  static const String getSteps = '/trackers/steps';

  // Medical Trackers
  static const String logVitals = '/trackers/vitals';
  static const String getVitals = '/trackers/vitals';
  static String deleteVitals(String id) => '/trackers/vitals/$id';

  static const String logGlucose = '/trackers/glucose';
  static const String getGlucose = '/trackers/glucose';
  static String deleteGlucose(String id) => '/trackers/glucose/$id';

  static const String logInsulin = '/trackers/insulin';
  static const String getInsulin = '/trackers/insulin';
  static String deleteInsulin(String id) => '/trackers/insulin/$id';

  static const String logMeasurement = '/trackers/measurements';
  static const String getMeasurements = '/trackers/measurements';
  static String deleteMeasurement(String id) => '/trackers/measurements/$id';
}

class NotificationEndpoints {
  static const String base = '/notifications';
  static String markAsRead(String id) => '/notifications/$id/read';
  static String delete(String id) => '/notifications/$id';
}

class AddressEndpoints {
  static const String base = '/addresses';
  static String update(String id) => '/addresses/$id';
  static String delete(String id) => '/addresses/$id';
  static String setDefault(String id) => '/addresses/$id/default';
}

class OrderEndpoints {
  static const String base = '/orders';
  static String getOne(String id) => '/orders/$id';
  static String cancel(String id) => '/orders/$id/cancel';
  static String status(String id) => '/orders/$id/status';
}

class DoctorEndpoints {
  static const String base = '/doctors';
  static String getOne(String id) => '/doctors/$id';
  static String getSlots(String id) => '/doctors/$id/slots';
}

class AppointmentEndpoints {
  static const String base = '/appointments';
  static String getOne(String id) => '/appointments/$id';
  static String delete(String id) => '/appointments/$id';
}

class HealthRecordEndpoints {
  static const String base = '/health-records';
  static String delete(String id) => '/health-records/$id';
}
