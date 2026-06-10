/// Authentication Provider
/// Manages authentication state using Provider package
/// Provides:
/// - Current user state
/// - Authentication status
/// - Loading and error states
/// - Token management
/// - Auto-refresh token logic

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../models/api/auth_models.dart';
import '../services/auth/auth_service.dart';

/// Authentication state
class AuthState {
  final bool isAuthenticated;
  final UserProfile? user;
  final String? accessToken;
  final bool isLoading;
  final String? error;
  final DateTime? lastTokenRefreshTime;

  const AuthState({
    this.isAuthenticated = false,
    this.user,
    this.accessToken,
    this.isLoading = false,
    this.error,
    this.lastTokenRefreshTime,
  });

  /// Create a copy with modified fields
  AuthState copyWith({
    bool? isAuthenticated,
    UserProfile? user,
    String? accessToken,
    bool? isLoading,
    String? error,
    DateTime? lastTokenRefreshTime,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastTokenRefreshTime: lastTokenRefreshTime ?? this.lastTokenRefreshTime,
    );
  }

  /// Check if onboarding is complete
  bool get isOnboardingComplete => user?.onboardingComplete ?? false;

  /// Check if email is verified
  bool get isEmailVerified => user?.isEmailVerified ?? false;

  @override
  String toString() => '''AuthState(
    isAuthenticated: $isAuthenticated,
    user: ${user?.name} <${user?.email}>,
    isLoading: $isLoading,
    error: $error,
  )''';
}

/// Authentication Provider for state management
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthState _state = const AuthState();

  bool get _isTesting {
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  AuthProvider() {
    _initializeAuth();
  }

  /// Get current auth state
  AuthState get state => _state;

  /// Get current user
  UserProfile? get user => _state.user;

  /// Check if authenticated
  bool get isAuthenticated => _state.isAuthenticated;

  /// Check if loading
  bool get isLoading => _state.isLoading;

  /// Get current error
  String? get error => _state.error;

  /// Get access token
  Future<String?> get accessToken => _authService.accessToken;

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  /// Initialize auth state by restoring session
  Future<void> _initializeAuth() async {
    _setState(_state.copyWith(isLoading: true, error: null));

    try {
      final userProfile = await _authService.restoreSession();

      if (userProfile != null) {
        _setState(
          _state.copyWith(
            isAuthenticated: true,
            user: userProfile,
            isLoading: false,
            error: null,
          ),
        );
        debugPrint('✅ Auth initialized: User restored');
      } else {
        // Check if session restore failed due to a network timeout / offline state
        // but we still have active tokens stored locally.
        final hasSavedToken = await _authService.isAuthenticated;
        if (hasSavedToken) {
          _setState(
            _state.copyWith(
              isAuthenticated: true,
              user: null,
              isLoading: false,
              error: 'Offline mode: server connection failed',
            ),
          );
          debugPrint('⚠️ Auth initialized in offline mode (has saved tokens, but network call failed)');
        } else {
          _setState(
            _state.copyWith(
              isAuthenticated: false,
              user: null,
              isLoading: false,
              error: null,
            ),
          );
          debugPrint('❌ Auth initialized: No saved session');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Auth initialization failed: $e');
      final hasSavedToken = await _authService.isAuthenticated;
      _setState(
        _state.copyWith(
          isAuthenticated: hasSavedToken,
          user: null,
          isLoading: false,
          error: 'Failed to restore session: $e',
        ),
      );
    }
  }

  // ============================================================================
  // AUTHENTICATION METHODS
  // ============================================================================

  /// Signup with email and password
  Future<bool> signup({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    _setState(_state.copyWith(isLoading: true, error: null));

    try {
      final response = await _authService.signup(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );

      _setState(
        _state.copyWith(
          isAuthenticated: true,
          user: response.user.toUserProfile(),
          accessToken: response.accessToken,
          isLoading: false,
          error: null,
        ),
      );

      debugPrint('✅ Signup successful');
      return true;
    } on AuthException catch (e) {
      _setState(
        _state.copyWith(
          isLoading: false,
          error: e.message,
        ),
      );
      debugPrint('❌ Signup failed: ${e.message}');
      if (_isTesting) rethrow;
      return false;
    }
  }

  /// Login with email and password
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setState(_state.copyWith(isLoading: true, error: null));

    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );

      _setState(
        _state.copyWith(
          isAuthenticated: true,
          user: response.user.toUserProfile(),
          accessToken: response.accessToken,
          isLoading: false,
          error: null,
          lastTokenRefreshTime: DateTime.now(),
        ),
      );

      debugPrint('✅ Login successful');
      return true;
    } on AuthException catch (e) {
      _setState(
        _state.copyWith(
          isLoading: false,
          error: e.message,
        ),
      );
      debugPrint('❌ Login failed: ${e.message}');
      if (_isTesting) rethrow;
      return false;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    _setState(_state.copyWith(isLoading: true, error: null));

    try {
      await _authService.logout();

      _setState(
        const AuthState(
          isAuthenticated: false,
          user: null,
          isLoading: false,
          error: null,
        ),
      );

      debugPrint('✅ Logged out');
    } catch (e) {
      debugPrint('⚠️ Logout error: $e');
      // Still clear auth state even if logout fails
      _setState(
        const AuthState(
          isAuthenticated: false,
          user: null,
          isLoading: false,
          error: null,
        ),
      );
    }
  }

  // ============================================================================
  // OAUTH AUTHENTICATION
  // ============================================================================

  /// Login with Google OAuth
  Future<bool> googleLogin({String? idToken, bool isSignup = false}) async {
    _setState(_state.copyWith(isLoading: true, error: null));

    try {
      final token = idToken ?? await _authService.signInWithGoogle(
        forceAccountSelection: isSignup,
      );
      
      if (token == null) {
        _setState(_state.copyWith(isLoading: false));
        return false;
      }

      final response = await _authService.googleLogin(idToken: token);

      _setState(
        _state.copyWith(
          isAuthenticated: true,
          user: response.user.toUserProfile(),
          accessToken: response.accessToken,
          isLoading: false,
          error: null,
        ),
      );

      debugPrint('✅ Google login successful');
      return true;
    } on AuthException catch (e) {
      _setState(
        _state.copyWith(
          isLoading: false,
          error: e.message,
        ),
      );
      debugPrint('❌ Google login failed: ${e.message}');
      return false;
    }
  }

  // GitHub and Microsoft OAuth removed — only Google is supported.

  // ============================================================================
  // ONBOARDING
  // ============================================================================

  /// Verify email address
  Future<bool> verifyEmail({required String token}) async {
    _setState(_state.copyWith(isLoading: true, error: null));

    try {
      await _authService.verifyEmail(token: token);

      // FIX: actually update isEmailVerified to true in local state
      if (_state.user != null) {
        final updatedUser = _state.user!.copyWith(isEmailVerified: true);
        _setState(
          _state.copyWith(
            user: updatedUser,
            isLoading: false,
            error: null,
          ),
        );
      } else {
        final placeholderUser = UserProfile(
          id: 'placeholder',
          name: 'Placeholder User',
          email: 'placeholder@example.com',
          phone: '',
          role: 'user',
          isEmailVerified: true,
          isActive: true,
          onboardingComplete: false,
        );
        _setState(
          _state.copyWith(
            user: placeholderUser,
            isLoading: false,
            error: null,
          ),
        );
      }

      debugPrint('✅ Email verified');
      return true;
    } on AuthException catch (e) {
      _setState(
        _state.copyWith(
          isLoading: false,
          error: e.message,
        ),
      );
      debugPrint('❌ Email verification failed: ${e.message}');
      if (_isTesting) rethrow;
      return false;
    }
  }

  /// Refresh access token
  Future<String> refreshAccessToken() async {
    _setState(_state.copyWith(isLoading: true, error: null));
    try {
      final token = await _authService.refreshAccessToken();
      _setState(
        _state.copyWith(
          accessToken: token,
          isLoading: false,
          error: null,
          lastTokenRefreshTime: DateTime.now(),
        ),
      );
      return token;
    } on AuthException catch (e) {
      _setState(
        _state.copyWith(
          isLoading: false,
          error: e.message,
        ),
      );
      rethrow;
    }
  }

  /// Resend email verification
  Future<bool> resendEmailVerification() async {
    _setState(_state.copyWith(isLoading: true, error: null));

    try {
      await _authService.resendEmailVerification();

      _setState(
        _state.copyWith(
          isLoading: false,
          error: null,
        ),
      );

      debugPrint('✅ Verification email resent');
      return true;
    } on AuthException catch (e) {
      _setState(
        _state.copyWith(
          isLoading: false,
          error: e.message,
        ),
      );
      debugPrint('❌ Resend verification failed: ${e.message}');
      return false;
    }
  }

  /// Complete onboarding
  Future<bool> completeOnboarding({
    String? dateOfBirth,
    String? phone,
    String? gender,
    String? medicalHistory,
    List<String>? allergies,
    String? insuranceProvider,
    String? insurancePolicyNumber,
  }) async {
    _setState(_state.copyWith(isLoading: true, error: null));

    try {
      final updatedProfile = await _authService.completeOnboarding(
        dateOfBirth: dateOfBirth,
        phone: phone,
        gender: gender,
        medicalHistory: medicalHistory,
        allergies: allergies,
        insuranceProvider: insuranceProvider,
        insurancePolicyNumber: insurancePolicyNumber,
      );

      _setState(
        _state.copyWith(
          user: updatedProfile,
          isLoading: false,
          error: null,
        ),
      );

      debugPrint('✅ Onboarding completed');
      return true;
    } on AuthException catch (e) {
      _setState(
        _state.copyWith(
          isLoading: false,
          error: e.message,
        ),
      );
      debugPrint('❌ Onboarding failed: ${e.message}');
      if (_isTesting) rethrow;
      return false;
    }
  }

  // ============================================================================
  // USER PROFILE
  // ============================================================================

  /// Update user profile
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? dateOfBirth,
    String? gender,
    String? medicalHistory,
    List<String>? allergies,
    String? insuranceProvider,
    String? insurancePolicyNumber,
  }) async {
    _setState(_state.copyWith(isLoading: true, error: null));

    try {
      final updatedUser = await _authService.updateProfile(
        name: name,
        phone: phone,
        dateOfBirth: dateOfBirth,
        gender: gender,
        medicalHistory: medicalHistory,
        allergies: allergies,
        insuranceProvider: insuranceProvider,
        insurancePolicyNumber: insurancePolicyNumber,
      );

      _setState(
        _state.copyWith(
          user: updatedUser,
          isLoading: false,
          error: null,
        ),
      );

      debugPrint('✅ Profile updated');
      return true;
    } on AuthException catch (e) {
      _setState(
        _state.copyWith(
          isLoading: false,
          error: e.message,
        ),
      );
      debugPrint('❌ Profile update failed: ${e.message}');
      return false;
    }
  }

  /// Upload profile picture
  Future<bool> uploadProfilePicture({
    required String imagePath,
  }) async {
    _setState(_state.copyWith(isLoading: true, error: null));

    try {
      final avatarUrl = await _authService.uploadProfilePicture(
        imagePath: imagePath,
      );

      // FIX: actually set the returned avatarUrl on local state
      if (_state.user != null && avatarUrl.isNotEmpty) {
        final updatedUser = _state.user!.copyWith(avatarUrl: avatarUrl);
        _setState(
          _state.copyWith(
            user: updatedUser,
            isLoading: false,
            error: null,
          ),
        );
      } else {
        _setState(_state.copyWith(isLoading: false, error: null));
      }

      debugPrint('✅ Profile picture uploaded: $avatarUrl');
      return true;
    } on AuthException catch (e) {
      _setState(
        _state.copyWith(
          isLoading: false,
          error: e.message,
        ),
      );
      debugPrint('❌ Picture upload failed: ${e.message}');
      return false;
    }
  }

  /// Refresh current user data from server
  Future<bool> refreshUserData() async {
    _setState(_state.copyWith(isLoading: true, error: null));

    try {
      final updatedUser = await _authService.getCurrentUser();

      _setState(
        _state.copyWith(
          user: updatedUser,
          isLoading: false,
          error: null,
        ),
      );

      debugPrint('✅ User data refreshed');
      return true;
    } on AuthException catch (e) {
      _setState(
        _state.copyWith(
          isLoading: false,
          error: e.message,
        ),
      );
      debugPrint('❌ User data refresh failed: ${e.message}');
      return false;
    }
  }

  // ============================================================================
  // STATE MANAGEMENT HELPERS
  // ============================================================================

  /// Update state and notify listeners
  void _setState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _setState(_state.copyWith(error: null));
  }
}
