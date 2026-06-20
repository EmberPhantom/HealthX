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
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
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

class TrackerEndpoints {
  static const String water = '/trackers/water';
  static const String sleep = '/trackers/sleep';
  static const String steps = '/trackers/steps';
  static const String vitals = '/trackers/vitals';
  static const String glucose = '/trackers/glucose';
  static const String insulin = '/trackers/insulin';
  static const String measurements = '/trackers/measurements';
}

class MealEndpoints {
  static const String log = '/meals/log';
  static const String getMeals = '/meals';
  static String delete(String id) => '/meals/$id';
  static const String identify = '/meals/identify';
  static const String identifyImage = '/meals/identify-image';
}

class DoctorEndpoints {
  static const String getDoctors = '/doctors';
  static String getDoctor(String id) => '/doctors/$id';
  static String getDoctorSlots(String id) => '/doctors/$id/slots';
}

class AppointmentEndpoints {
  static const String base = '/appointments';
  static String getAppointment(String id) => '/appointments/$id';
  static String cancelAppointment(String id) => '/appointments/$id';
  static String rescheduleAppointment(String id) => '/appointments/$id/reschedule';
}

class ChatEndpoints {
  static String getMessages(String appointmentId) => '/chats/$appointmentId/messages';
  static String sendMessage(String appointmentId) => '/chats/$appointmentId/messages';
}

class PrescriptionEndpoints {
  static String getPrescription(String appointmentId) => '/prescriptions/$appointmentId';
}

class SubscriptionEndpoints {
  static const String base = '/subscriptions';
  static const String subscribe = '/subscriptions/subscribe';
  static String pause(String id) => '/subscriptions/pause/$id';
  static String cancel(String id) => '/subscriptions/cancel/$id';
  static const String me = '/subscriptions/me';
}

class AIHealthEndpoints {
  static const String step5Questions = '/ai-health/step5-questions';
  static const String submitAnalysis = '/ai-health/analyze';
  static const String profile = '/ai-health/profile';
  static const String profileStatus = '/ai-health/profile/status';
  static const String mealWarning = '/ai-health/meal-warning';
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
