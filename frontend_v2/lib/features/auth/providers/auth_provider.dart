import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class AuthNotifier extends Notifier<AuthState> {
  final AuthService _authService = AuthService();

  @override
  AuthState build() {
    Future.microtask(() => initializeAuth());
    return const AuthState();
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
      final token = await _authService.signInWithGoogle(forceAccountSelection: true);
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
    String? avatarUrl,
    String? medicalHistory,
    List<String>? allergies,
    List<String>? medications,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? insuranceProvider,
    String? insurancePolicyNumber,
    double? height,
    double? weight,
    bool? isDiabetesPatient,
    bool? isBpPatient,
    List<String>? wellnessGoals,
    String? dominantDosha,
    int? activityLevel,
    int? age,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updatedProfile = await _authService.completeOnboarding(
        dateOfBirth: dateOfBirth,
        phone: phone,
        gender: gender,
        avatarUrl: avatarUrl,
        medicalHistory: medicalHistory,
        allergies: allergies,
        medications: medications,
        emergencyContactName: emergencyContactName,
        emergencyContactPhone: emergencyContactPhone,
        insuranceProvider: insuranceProvider,
        insurancePolicyNumber: insurancePolicyNumber,
        height: height,
        weight: weight,
        isDiabetesPatient: isDiabetesPatient,
        isBpPatient: isBpPatient,
        wellnessGoals: wellnessGoals,
        dominantDosha: dominantDosha,
        activityLevel: activityLevel,
        age: age,
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

  void updatePointsLocally(int newPoints) {
    if (state.user != null) {
      state = state.copyWith(user: state.user!.copyWith(points: newPoints));
    }
  }

  void updateLocalUserDosha(String dosha) {
    if (state.user != null) {
      state = state.copyWith(user: state.user!.copyWith(dominantDosha: dosha));
    }
  }

  Future<bool> updateUserProfile({
    String? name,
    String? phone,
    String? gender,
    int? age,
    String? avatarUrl,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await _authService.updateProfile(
        name: name,
        phone: phone,
        gender: gender,
        age: age,
        avatarUrl: avatarUrl,
      );
      state = state.copyWith(
        user: updated,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateUserSettings({
    int? dailyWaterGoalMl,
    int? dailyStepGoal,
    int? dailyCalorieGoal,
    int? dailyProteinGoalG,
    int? dailyCarbGoalG,
    int? dailyFatGoalG,
    bool? reminderEnabled,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await _authService.updateSettings(
        dailyWaterGoalMl: dailyWaterGoalMl,
        dailyStepGoal: dailyStepGoal,
        dailyCalorieGoal: dailyCalorieGoal,
        dailyProteinGoalG: dailyProteinGoalG,
        dailyCarbGoalG: dailyCarbGoalG,
        dailyFatGoalG: dailyFatGoalG,
        reminderEnabled: reminderEnabled,
      );
      state = state.copyWith(
        user: updated,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<String?> forgotPassword({required String email}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.forgotPassword(email: email);
      state = state.copyWith(isLoading: false);
      return null;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return e.message;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return e.toString();
    }
  }

  Future<String?> resetPassword({
    required String token,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.resetPassword(token: token, password: password);
      state = state.copyWith(isLoading: false);
      return null;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return e.message;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return e.toString();
    }
  }

  Future<bool> deleteUserAccount() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _authService.deleteAccount();
      if (success) {
        state = const AuthState(
          isAuthenticated: false,
          user: null,
          isLoading: false,
        );
        return true;
      }
      state = state.copyWith(isLoading: false, error: 'Failed to delete account.');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> toggleFavorite(String itemId) async {
    try {
      final updatedFavorites = await _authService.toggleFavorite(itemId);
      if (state.user != null) {
        state = state.copyWith(
          user: state.user!.copyWith(favorites: updatedFavorites),
        );
      }
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

final sessionProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).user?.id;
});
