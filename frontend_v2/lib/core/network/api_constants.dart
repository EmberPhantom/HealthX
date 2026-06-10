/// API Constants and Configuration for HealthX
/// Defines all backend endpoints, base URLs, and timeout values
import 'package:flutter/foundation.dart';

enum ApiEnvironment {
  development,
  staging,
  production,
}

const ApiEnvironment currentEnvironment = ApiEnvironment.development;

class ApiConfig {
  static const Map<ApiEnvironment, String> baseUrls = {
    ApiEnvironment.staging: 'https://staging-api.healthx.com',
    ApiEnvironment.production: 'https://api.healthx.com',
    ApiEnvironment.development: 'http://localhost:3000',
  };

  static const String _devHost = String.fromEnvironment('DEV_HOST', defaultValue: '');

  static String get baseUrl {
    if (currentEnvironment == ApiEnvironment.development) {
      if (kIsWeb) return 'http://localhost:3000';

      if (_devHost.isNotEmpty) {
        return 'http://$_devHost:3000';
      }

      const String manualIp = ''; // Set LAN IP here if testing on physical phone
      if (manualIp.isNotEmpty) {
        return 'http://$manualIp:3000';
      }

      try {
        if (defaultTargetPlatform == TargetPlatform.android) {
          return 'http://10.0.2.2:3000'; // Standard Android Emulator loopback
        }
      } catch (_) {}

      return 'http://localhost:3000';
    }
    return baseUrls[currentEnvironment] ?? 'http://localhost:3000';
  }

  static const String apiVersion = '/api/v1';
  static String get apiBasePath => '$baseUrl$apiVersion';

  static const int requestTimeoutSeconds = 30;
  static const int connectionTimeoutSeconds = 20;
  static const int receiveTimeoutSeconds = 30;

  static bool get enableLogging => kDebugMode;
  static bool get enableDebugLogging => kDebugMode;
}

class AuthEndpoints {
  static const String signup = '/auth/signup';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String googleAuth = '/auth/google';
  static const String getMe = '/auth/me';
  static const String updateMe = '/auth/me';
  static const String uploadProfilePicture = '/auth/me/upload-picture';
  static const String linkOAuthProvider = '/auth/link';
  static const String unlinkOAuthProvider = '/auth/unlink';
}

class OnboardingEndpoints {
  static const String verifyEmail = '/onboarding/verify-email';
  static const String resendVerification = '/onboarding/resend-verification';
  static const String completeOnboarding = '/onboarding/complete';
  static const String onboardingStatus = '/onboarding/status';
}

class UserEndpoints {
  static const String getProfile = '/users/me';
  static const String updateProfile = '/users/me';
  static const String getStats = '/users/me/stats';
  static const String getSettings = '/users/me/settings';
  static const String updateSettings = '/users/me/settings';
  static const String toggleFavorite = '/users/me/favorites/toggle';
  static const String updateWellnessGoals = '/users/me/wellness-goals';
}

class TokenConfig {
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
}

class ErrorMessages {
  static const String noConnection = 'No internet connection';
  static const String networkTimeout = 'Request timed out. Please check your connection.';
  static const String serverError = 'Server error. Please try again later.';
  static const String somethingWentWrong = 'Something went wrong. Please try again.';
}

class ApiHeaders {
  static const String authorization = 'Authorization';
  static const String authorizationBearer = 'Bearer';
}
