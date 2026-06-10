import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../core/models/auth_models.dart';
import '../services/auth_service.dart';

class AuthState {
  final bool isAuthenticated;
  final UserProfile? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    UserProfile? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  bool get isOnboardingComplete => user?.onboardingComplete ?? false;
  bool get isEmailVerified => user?.isEmailVerified ?? false;

  @override
  String toString() => 'AuthState(isAuthenticated: $isAuthenticated, user: ${user?.name}, isLoading: $isLoading, error: $error)';
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService = AuthService();

  AuthNotifier() : super(const AuthState()) {
    initializeAuth();
  }

  Future<void> initializeAuth() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userProfile = await _authService.restoreSession();
      if (userProfile != null) {
        state = state.copyWith(
          isAuthenticated: true,
          user: userProfile,
          isLoading: false,
        );
      } else {
        final hasSavedToken = await _authService.isAuthenticated;
        state = state.copyWith(
          isAuthenticated: hasSavedToken,
          user: null,
          isLoading: false,
          error: hasSavedToken ? 'Connection lost. Operating in offline mode.' : null,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to restore session: $e',
      );
    }
  }

  Future<bool> signup({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authService.signup(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );
      state = state.copyWith(
        isAuthenticated: true,
        user: response.user.toUserProfile(),
        isLoading: false,
      );
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Registration failed: $e');
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );
      state = state.copyWith(
        isAuthenticated: true,
        user: response.user.toUserProfile(),
        isLoading: false,
      );
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Login failed: $e');
      return false;
    }
  }

  Future<bool> googleLogin({bool isSignup = false}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = await _authService.signInWithGoogle(forceAccountSelection: isSignup);
      if (token == null) {
        state = state.copyWith(isLoading: false);
        return false;
      }

      final response = await _authService.googleLogin(idToken: token);
      state = state.copyWith(
        isAuthenticated: true,
        user: response.user.toUserProfile(),
        isLoading: false,
      );
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Google sign-in failed: $e');
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.logout();
    } catch (_) {
    } finally {
      state = const AuthState(
        isAuthenticated: false,
        user: null,
        isLoading: false,
      );
    }
  }

  Future<bool> completeOnboarding({
    String? dateOfBirth,
    String? phone,
    String? gender,
    String? medicalHistory,
    List<String>? allergies,
    String? insuranceProvider,
    String? insurancePolicyNumber,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
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
      state = state.copyWith(
        user: updatedProfile,
        isLoading: false,
      );
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to complete onboarding: $e');
      return false;
    }
  }

  Future<bool> uploadProfilePicture({required String imagePath}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final avatarUrl = await _authService.uploadProfilePicture(imagePath: imagePath);
      if (state.user != null && avatarUrl.isNotEmpty) {
        state = state.copyWith(
          user: state.user!.copyWith(avatarUrl: avatarUrl),
          isLoading: false,
        );
        return true;
      }
      state = state.copyWith(isLoading: false);
      return false;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Image upload failed: $e');
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
