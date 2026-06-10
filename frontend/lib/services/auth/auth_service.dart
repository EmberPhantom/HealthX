/// Authentication Service
/// Business logic layer wrapping API calls with auth-specific functionality
/// Handles:
/// - Signup/login workflows
/// - Token lifecycle management
/// - Google OAuth integration
/// - Session restoration
/// - Error handling and transformation

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/api/api_response.dart';
import '../../models/api/auth_models.dart';
import '../api/api_constants.dart';
import '../api/api_service.dart';
import '../api/secure_storage_simple.dart';

/// Exception thrown by AuthService
class AuthException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AuthException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'AuthException: $message${code != null ? ' ($code)' : ''}';
}

/// Authentication service handling auth operations
class AuthService {
  static final AuthService _instance = AuthService._internal();

  ApiService get _apiService => ApiService();
  final SecureStorage _secureStorage = SecureStorage();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  // ============================================================================
  // PROPERTY GETTERS
  // ============================================================================

  /// Check if user is currently authenticated (has saved access token)
  Future<bool> get isAuthenticated async {
    return await _secureStorage.isAuthenticated();
  }

  /// Get current access token from secure storage
  Future<String?> get accessToken async {
    return await _secureStorage.getToken();
  }

  /// Get current refresh token from secure storage
  Future<String?> get refreshToken async {
    return await _secureStorage.getRefreshToken();
  }

  // ============================================================================
  // AUTHENTICATION
  // ============================================================================

  /// Signup with email and password
  /// Throws [AuthException] on failure
  /// Returns [AuthResponse] with tokens and user info
  Future<AuthResponse> signup({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      _validateName(name);
      _validateEmail(email);
      _validatePassword(password);

      debugPrint('📝 Signing up: $email');

      final response = await _apiService.signup(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );

      if (!response.isSuccess || response.data == null) {
        throw AuthException(
          message: response.errorMessage ?? 'Signup failed',
          code: 'SIGNUP_FAILED',
        );
      }

      // NOTE: ApiService.signup() already saves tokens to secure storage.
      debugPrint('✅ Signup successful for: ${response.data!.user.email}');
      return response.data!;
    } catch (e) {
      throw _handleError(e, 'Signup failed');
    }
  }

  /// Login with email and password
  /// Throws [AuthException] on failure
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      _validateEmail(email);
      _validatePassword(password);

      debugPrint('🔐 Logging in: $email');

      final response = await _apiService.login(
        email: email,
        password: password,
      );

      if (!response.isSuccess || response.data == null) {
        throw AuthException(
          message: response.errorMessage ?? 'Login failed',
          code: 'LOGIN_FAILED',
        );
      }

      // NOTE: ApiService.login() already saves tokens to secure storage.
      debugPrint('✅ Login successful for: ${response.data!.user.email}');
      return response.data!;
    } catch (e) {
      throw _handleError(e, 'Login failed');
    }
  }

  /// Logout current user
  /// Clears tokens and session data
  /// Does not throw on error (graceful logout)
  Future<void> logout() async {
    try {
      debugPrint('🚪 Logging out');
      await _apiService.logout();
    } catch (e) {
      debugPrint('⚠️ Logout API call failed: $e');
      // Continue with local logout even if API fails
    } finally {
      // Sign out of Google Sign-In so that account selection popup appears next time
      try {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.signOut();
          debugPrint('✅ Google session signed out');
        }
      } catch (ge) {
        debugPrint('⚠️ Google Sign-out error: $ge');
      }

      // Clear local tokens regardless of API response
      await _secureStorage.clearAllTokens();
      debugPrint('✅ Logged out (local tokens cleared)');
    }
  }

  /// Refresh access token using refresh token
  /// Called automatically when access token expires (401)
  /// Throws [AuthException] if refresh fails
  Future<String> refreshAccessToken() async {
    try {
      final currentRefreshToken = await _secureStorage.getRefreshToken();

      if (currentRefreshToken == null) {
        throw AuthException(
          message: 'No refresh token available',
          code: 'NO_REFRESH_TOKEN',
        );
      }

      debugPrint('🔄 Refreshing access token');

      final response = await _apiService.refreshToken(
        refreshToken: currentRefreshToken,
      );

      if (!response.isSuccess || response.data == null) {
        await logout();
        throw AuthException(
          message: 'Token refresh failed',
          code: 'TOKEN_REFRESH_FAILED',
        );
      }

      debugPrint('✅ Access token refreshed');
      return response.data!.accessToken;
    } catch (e) {
      throw _handleError(e, 'Token refresh failed');
    }
  }

  // ============================================================================
  // GOOGLE OAUTH
  // ============================================================================

  /// Perform Google Sign-in and return the ID token
  Future<String?> signInWithGoogle({bool forceAccountSelection = false}) async {
    try {
      debugPrint('🔵 Starting Google Sign-in flow (forceSelection: $forceAccountSelection)');
      
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
      
      // Force account selection by signing out first
      if (forceAccountSelection) {
        await googleSignIn.signOut();
      }

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('⚠️ Google Sign-in cancelled by user');
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // We need the ID token to send to our backend
      final String? idToken = googleAuth.idToken;
      
      if (idToken == null) {
        throw AuthException(
          message: 'Failed to obtain Google ID token',
          code: 'ID_TOKEN_MISSING',
        );
      }

      debugPrint('✅ Google ID token obtained');
      return idToken;
    } catch (e) {
      debugPrint('❌ Google Sign-in error: $e');
      throw _handleError(e, 'Google Sign-in failed');
    }
  }

  /// Login with Google OAuth — only supported social provider
  /// Use with Google Sign-In + Firebase Auth to get idToken
  /// Throws [AuthException] on failure
  Future<AuthResponse> googleLogin({required String idToken}) async {
    try {
      debugPrint('🔵 Google login with ID token');

      if (idToken.isEmpty) {
        throw AuthException(
          message: 'Invalid Google ID token',
          code: 'INVALID_ID_TOKEN',
        );
      }

      final response = await _apiService.googleLogin(idToken: idToken);

      if (!response.isSuccess || response.data == null) {
        throw AuthException(
          message: response.errorMessage ?? 'Google login failed',
          code: 'GOOGLE_LOGIN_FAILED',
        );
      }

      // NOTE: ApiService.googleLogin() already saves tokens to secure storage.
      debugPrint('✅ Google login successful for: ${response.data!.user.email}');
      return response.data!;
    } catch (e) {
      throw _handleError(e, 'Google login failed');
    }
  }

  // ============================================================================
  // ONBOARDING
  // ============================================================================

  /// Verify email address with token
  /// Throws [AuthException] on failure
  Future<void> verifyEmail({required String token}) async {
    try {
      if (token.isEmpty) {
        throw AuthException(
          message: 'Invalid verification token',
          code: 'INVALID_TOKEN',
        );
      }

      debugPrint('📧 Verifying email');

      final response = await _apiService.verifyEmail(token: token);

      if (!response.isSuccess) {
        throw AuthException(
          message: response.errorMessage ?? 'Email verification failed',
          code: 'EMAIL_VERIFICATION_FAILED',
        );
      }

      debugPrint('✅ Email verified successfully');
    } catch (e) {
      throw _handleError(e, 'Email verification failed');
    }
  }

  /// Resend email verification link
  /// Throws [AuthException] on failure
  Future<void> resendEmailVerification() async {
    try {
      debugPrint('📬 Resending verification email');

      final response = await _apiService.resendVerification();

      if (!response.isSuccess) {
        throw AuthException(
          message: response.errorMessage ?? 'Failed to resend verification email',
          code: 'RESEND_VERIFICATION_FAILED',
        );
      }

      debugPrint('✅ Verification email resent');
    } catch (e) {
      throw _handleError(e, 'Failed to resend verification email');
    }
  }

  /// Complete user onboarding with profile information
  /// Throws [AuthException] on failure
  Future<UserProfile> completeOnboarding({
    String? dateOfBirth,
    String? phone,
    String? gender,
    String? medicalHistory,
    List<String>? allergies,
    String? insuranceProvider,
    String? insurancePolicyNumber,
  }) async {
    try {
      debugPrint('📋 Completing onboarding');

      final response = await _apiService.completeOnboarding(
        dateOfBirth: dateOfBirth,
        phone: phone,
        gender: gender,
        medicalHistory: medicalHistory,
        allergies: allergies,
        insuranceProvider: insuranceProvider,
        insurancePolicyNumber: insurancePolicyNumber,
      );

      if (!response.isSuccess || response.data == null) {
        throw AuthException(
          message: response.errorMessage ?? 'Failed to complete onboarding',
          code: 'ONBOARDING_FAILED',
        );
      }

      debugPrint('✅ Onboarding completed');
      return response.data!;
    } catch (e) {
      throw _handleError(e, 'Failed to complete onboarding');
    }
  }

  /// Get onboarding status
  /// Returns completion percentage and pending fields
  /// Throws [AuthException] on failure
  Future<OnboardingStatus> getOnboardingStatus() async {
    try {
      final response = await _apiService.getOnboardingStatus();

      if (!response.isSuccess || response.data == null) {
        throw AuthException(
          message: response.errorMessage ?? 'Failed to get onboarding status',
          code: 'GET_STATUS_FAILED',
        );
      }

      return response.data!;
    } catch (e) {
      throw _handleError(e, 'Failed to get onboarding status');
    }
  }

  // ============================================================================
  // USER PROFILE
  // ============================================================================

  /// Get current user profile from backend
  /// Throws [AuthException] on failure
  Future<UserProfile> getCurrentUser() async {
    try {
      final response = await _apiService.getProfile();

      if (!response.isSuccess || response.data == null) {
        throw response;
      }

      return response.data!;
    } catch (e) {
      throw _handleError(e, 'Failed to fetch user profile');
    }
  }

  /// Update user profile
  /// Throws [AuthException] on failure
  Future<UserProfile> updateProfile({
    String? name,
    String? phone,
    String? dateOfBirth,
    String? gender,
    String? medicalHistory,
    List<String>? allergies,
    String? insuranceProvider,
    String? insurancePolicyNumber,
  }) async {
    try {
      debugPrint('✏️ Updating profile');

      final response = await _apiService.updateProfile(
        name: name,
        phone: phone,
        gender: gender,
      );

      if (!response.isSuccess || response.data == null) {
        throw AuthException(
          message: response.errorMessage ?? 'Failed to update profile',
          code: 'UPDATE_PROFILE_FAILED',
        );
      }

      debugPrint('✅ Profile updated');
      return response.data!;
    } catch (e) {
      throw _handleError(e, 'Failed to update profile');
    }
  }

  /// Upload profile picture
  /// Throws [AuthException] on failure
  /// Provides progress callback during upload
  Future<String> uploadProfilePicture({
    required String imagePath,
    ProgressCallback? onProgress,
  }) async {
    try {
      debugPrint('📸 Uploading profile picture');

      final response = await _apiService.uploadProfilePicture(
        imagePath: imagePath,
        onProgress: onProgress,
      );

      if (!response.isSuccess || response.data == null) {
        throw AuthException(
          message: response.errorMessage ?? 'Failed to upload profile picture',
          code: 'UPLOAD_PICTURE_FAILED',
        );
      }

      debugPrint('✅ Profile picture uploaded');
      return response.data!.value;
    } catch (e) {
      throw _handleError(e, 'Failed to upload profile picture');
    }
  }

  // ============================================================================
  // SESSION MANAGEMENT
  // ============================================================================

  /// Restore user session from saved tokens.
  /// Called on app startup to restore logged-in state.
  ///
  /// Returns the [UserProfile] if the session is valid.
  /// Returns null (WITHOUT clearing tokens) on network errors so the user
  /// is not logged out just because the server was slow at startup.
  /// Only clears tokens on a definitive 401 Unauthorized response.
  Future<UserProfile?> restoreSession() async {
    debugPrint('🔄 Restoring session');

    final token = await _secureStorage.getToken();
    if (token == null) {
      debugPrint('❌ No saved token found — fresh install or previously logged out');
      return null;
    }

    try {
      // Fetch user profile with saved token
      // Timeout is handled by Dio, but we wrap it in a local timeout just in case
      final userProfile = await getCurrentUser().timeout(const Duration(seconds: 10));
      debugPrint('✅ Session restored for: ${userProfile.email}');
      return userProfile;
    } on TimeoutException catch (_) {
      debugPrint('⚠️ Session restore timed out after 10s — keeping tokens for retry');
      return null;
    } on AuthException catch (e) {
      // Only wipe tokens on a definitive auth failure (401 / token invalid).
      // Network timeouts and connection errors must NOT log the user out.
      final isNetworkError = e.code == 'NETWORK_TIMEOUT' ||
          e.code == 'NO_CONNECTION' ||
          (e.originalError is ApiResponse &&
              ((e.originalError as ApiResponse).statusCode == 0 ||
                  (e.originalError as ApiResponse).statusCode == -1)) ||
          (e.originalError is DioException &&
              ((e.originalError as DioException).type ==
                      DioExceptionType.connectionTimeout ||
                  (e.originalError as DioException).type ==
                      DioExceptionType.connectionError ||
                  (e.originalError as DioException).type ==
                      DioExceptionType.receiveTimeout ||
                  (e.originalError as DioException).type ==
                      DioExceptionType.sendTimeout));

      if (isNetworkError) {
        debugPrint('⚠️ Session restore failed due to network error — keeping tokens for retry: $e');
        // Return null so AuthProvider shows login screen, but tokens are preserved.
        // On next successful network call, the user can sign in again or the
        // auto-token-refresh interceptor will handle token renewal.
        return null;
      }

      // For genuine auth failures (401, invalid token), clear and force re-login.
      debugPrint('❌ Session invalid (auth error) — clearing tokens: $e');
      await _secureStorage.clearAllTokens();
      return null;
    } catch (e) {
      // Unexpected errors: log but don't clear tokens.
      debugPrint('⚠️ Unexpected error during session restore — keeping tokens: $e');
      return null;
    }
  }

  // ============================================================================
  // VALIDATION HELPERS
  // ============================================================================

  void _validateEmail(String email) {
    if (email.isEmpty) {
      throw AuthException(message: 'Email is required', code: 'EMAIL_REQUIRED');
    }
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
      throw AuthException(message: 'Invalid email address', code: 'INVALID_EMAIL');
    }
  }

  void _validatePassword(String password) {
    if (password.isEmpty) {
      throw AuthException(message: 'Password is required', code: 'PASSWORD_REQUIRED');
    }
    if (password.length < 8) {
      throw AuthException(
          message: 'Password must be at least 8 characters', code: 'PASSWORD_TOO_SHORT');
    }
  }

  void _validateName(String name) {
    if (name.isEmpty) {
      throw AuthException(message: 'Name is required', code: 'NAME_REQUIRED');
    }
    if (name.length < 2) {
      throw AuthException(message: 'Name must be at least 2 characters', code: 'NAME_TOO_SHORT');
    }
  }

  // ============================================================================
  // ERROR HANDLING
  // ============================================================================

  AuthException _handleError(dynamic error, String defaultMessage) {
    if (error is AuthException) return error;

    if (error is ApiResponse) {
      final code = error.statusCode == 0
          ? 'NETWORK_TIMEOUT'
          : (error.statusCode == -1 ? 'NO_CONNECTION' : 'API_ERROR');
      return AuthException(
        message: error.errorMessage ?? defaultMessage,
        code: code,
        originalError: error,
      );
    }

    // Map Dio network errors to well-known codes so restoreSession() can
    // distinguish between network failures and true auth failures.
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return AuthException(
            message: ErrorMessages.networkTimeout,
            code: 'NETWORK_TIMEOUT',
            originalError: error,
          );
        case DioExceptionType.connectionError:
          return AuthException(
            message: ErrorMessages.noConnection,
            code: 'NO_CONNECTION',
            originalError: error,
          );
        default:
          break;
      }
    }

    debugPrint('❌ Auth error: $error');
    return AuthException(
      message: defaultMessage,
      code: 'UNKNOWN_ERROR',
      originalError: error,
    );
  }
}

/// Callback for upload progress
typedef ProgressCallback = Function(int sentBytes, int totalBytes);
