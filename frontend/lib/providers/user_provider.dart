import 'package:flutter/foundation.dart';
import 'package:healthx/models/api/auth_models.dart';
import 'package:healthx/services/api/api_service.dart';
import 'package:healthx/utils/error_handler.dart';

/// User data state class - immutable representation of user state
class UserState {
  /// Current user profile (null if no user)
  final UserProfile? user;

  /// Loading indicator for async operations
  final bool isLoading;

  /// Error message if operation failed
  final String? error;

  /// Last time user data was fetched
  final DateTime? lastFetchTime;

  /// Indicates if user profile is complete
  bool get isProfileComplete =>
      user != null &&
      user!.onboardingComplete == true &&
      user!.isEmailVerified == true;

  /// Indicates if user has pending updates
  bool get hasPendingUpdates =>
      user != null && user!.onboardingComplete == false;

  /// Getter for user email
  String? get userEmail => user?.email;

  /// Getter for user name
  String? get userName => user?.name;

  /// Getter for user phone
  String? get userPhone => user?.phone;

  /// Constructor
  UserState({
    this.user,
    this.isLoading = false,
    this.error,
    this.lastFetchTime,
  });

  /// Create a copy with modified fields
  UserState copyWith({
    UserProfile? user,
    bool? isLoading,
    String? error,
    DateTime? lastFetchTime,
  }) {
    return UserState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastFetchTime: lastFetchTime ?? this.lastFetchTime,
    );
  }

  /// Clear error message
  UserState clearError() => copyWith(error: null);

  /// Set loading state
  UserState setLoading(bool loading) => copyWith(isLoading: loading);

  /// Debug string representation
  @override
  String toString() =>
      'UserState(user: ${user?.name}, isLoading: $isLoading, error: $error)';
}

/// Provider exception for user-specific errors
class UserException implements Exception {
  final String message;
  final String? code;
  final Exception? originalException;

  UserException(
    this.message, {
    this.code,
    this.originalException,
  });

  @override
  String toString() => 'UserException: $message${code != null ? ' [$code]' : ''}';
}

/// User data provider - manages user profile and related operations
class UserProvider extends ChangeNotifier {
  /// Current user state
  UserState _state = UserState();

  /// Getter for current state
  UserState get state => _state;

  /// Getter for current user
  UserProfile? get user => _state.user;

  /// Getter for loading state
  bool get isLoading => _state.isLoading;

  /// Getter for error
  String? get error => _state.error;

  /// API service instance
  final ApiService _apiService;

  /// Error handler instance
  final ErrorHandler _errorHandler;

  /// Constructor
  UserProvider({
    ApiService? apiService,
    ErrorHandler? errorHandler,
    bool autoInitialize = false,
  })  : _apiService = apiService ?? ApiService(),
        _errorHandler = errorHandler ?? ErrorHandler() {
    if (autoInitialize) {
      _initializeUser();
    }
  }

  /// Initialize user data on provider creation
  Future<void> _initializeUser() async {
    // Start with loading state
    _setLoading(true);

    try {
      // Try to fetch current user profile
      final result = await _apiService.getProfile();

      if (result.success && result.data != null) {
        _state = _state.copyWith(
          user: result.data,
          isLoading: false,
          error: null,
          lastFetchTime: DateTime.now(),
        );
      } else {
        // Clear user if fetch failed
        _state = _state.copyWith(
          user: null,
          isLoading: false,
          error: 'Failed to load user profile',
        );
      }
    } catch (e) {
      _state = _state.copyWith(
        user: null,
        isLoading: false,
        error: 'Failed to initialize user profile',
      );
      debugPrint('UserProvider initialization error: $e');
    }

    notifyListeners();
  }

  /// Fetch current user profile from server
  Future<UserProfile?> fetchUserProfile() async {
    _setLoading(true);

    try {
      final result = await _apiService.getProfile();

      if (result.success && result.data != null) {
        _state = _state.copyWith(
          user: result.data,
          isLoading: false,
          error: null,
          lastFetchTime: DateTime.now(),
        );
        notifyListeners();
        return result.data;
      } else {
        _state = _state.copyWith(
          isLoading: false,
          error: result.message ?? 'Failed to fetch user profile',
        );
        notifyListeners();
        return null;
      }
    } catch (e) {
      final appError = _errorHandler.handleError(e);
      _state = _state.copyWith(
        isLoading: false,
        error: appError.message,
      );
      notifyListeners();

      debugPrint('Error fetching user profile: $e');
      throw UserException(
        appError.message,
        code: appError.type.toString(),
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Update user profile with new data
  Future<UserProfile?> updateProfile({
    required String name,
    String? phone,
    String? avatar,
  }) async {
    _setLoading(true);

    try {
      // Validate input
      if (name.isEmpty || name.length < 2) {
        throw UserException('Name must be at least 2 characters');
      }

      // Call API
      final result = await _apiService.updateProfile(
        name: name,
        phone: phone,
      );

      if (result.success && result.data != null) {
        _state = _state.copyWith(
          user: result.data,
          isLoading: false,
          error: null,
          lastFetchTime: DateTime.now(),
        );
        notifyListeners();
        debugPrint('✅ User profile updated: $name');
        return result.data;
      } else {
        _state = _state.copyWith(
          isLoading: false,
          error: result.message ?? 'Failed to update profile',
        );
        notifyListeners();
        return null;
      }
    } catch (e) {
      final appError = _errorHandler.handleError(e);
      _state = _state.copyWith(
        isLoading: false,
        error: appError.message,
      );
      notifyListeners();

      debugPrint('Error updating profile: $e');
      throw UserException(
        appError.message,
        code: appError.type.toString(),
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Complete user onboarding with optional profile data
  Future<UserProfile?> completeOnboarding({
    String? avatarPath,
    String? name,
    String? phone,
    String? dateOfBirth,
    String? gender,
    bool? hasInsurance,
    String? insuranceProvider,
  }) async {
    _setLoading(true);

    try {
      // Call API
      final result = await _apiService.completeOnboarding(
        phone: phone,
        gender: gender,
        dateOfBirth: dateOfBirth,
        insuranceProvider: insuranceProvider,
      );

      if (result.success && result.data != null) {
        _state = _state.copyWith(
          user: result.data,
          isLoading: false,
          error: null,
          lastFetchTime: DateTime.now(),
        );
        notifyListeners();
        debugPrint('✅ Onboarding completed');
        return result.data;
      } else {
        _state = _state.copyWith(
          isLoading: false,
          error: result.message ?? 'Failed to complete onboarding',
        );
        notifyListeners();
        return null;
      }
    } catch (e) {
      final appError = _errorHandler.handleError(e);
      _state = _state.copyWith(
        isLoading: false,
        error: appError.message,
      );
      notifyListeners();

      debugPrint('Error completing onboarding: $e');
      throw UserException(
        appError.message,
        code: appError.type.toString(),
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Refresh user data if cache is stale (default: 5 minutes)
  Future<UserProfile?> refreshUserIfNeeded({
    Duration cacheValidity = const Duration(minutes: 5),
  }) async {
    final lastFetch = _state.lastFetchTime;

    // Return cached data if recent enough
    if (lastFetch != null && DateTime.now().difference(lastFetch) < cacheValidity) {
      debugPrint('Using cached user profile (${DateTime.now().difference(lastFetch).inSeconds}s old)');
      return _state.user;
    }

    // Fetch fresh data
    return fetchUserProfile();
  }

  /// Set user directly (e.g., from auth provider)
  void setUser(UserProfile? user) {
    _state = _state.copyWith(
      user: user,
      error: null,
      lastFetchTime: user != null ? DateTime.now() : null,
    );
    notifyListeners();
    debugPrint('User set: ${user?.name ?? "null"}');
  }

  /// Clear user data
  void clearUser() {
    _state = UserState();
    notifyListeners();
    debugPrint('User cleared');
  }

  /// Clear error message
  void clearError() {
    _state = _state.clearError();
    notifyListeners();
  }

  /// Check if user data needs refresh
  bool get needsRefresh {
    if (_state.lastFetchTime == null) return true;
    return DateTime.now().difference(_state.lastFetchTime!).inMinutes > 5;
  }

  /// Get user initials for avatar display
  String get userInitials {
    if (_state.user?.name == null || _state.user!.name.isEmpty) {
      return '?';
    }
    final parts = _state.user!.name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  /// Get user display name
  String get displayName => _state.user?.name ?? 'User';

  /// Helper to set loading state
  void _setLoading(bool loading) {
    _state = _state.setLoading(loading);
  }

  /// Sync user profile with auth user
  void syncWithAuth(UserProfile? authUser) {
    if (authUser == null) {
      if (_state.user != null) {
        clearUser();
      }
      return;
    }
    if (_state.user?.id != authUser.id) {
      setUser(authUser);
      // Fetch full profile data
      fetchUserProfile();
    }
  }

  /// Print debug information
  void printDebugInfo() {
    debugPrint('''
╔════════════════════════════════════════╗
║       USER PROVIDER DEBUG INFO         ║
╚════════════════════════════════════════╝
User: ${_state.user?.name ?? 'None'}
Email: ${_state.user?.email ?? 'None'}
Phone: ${_state.user?.phone ?? 'None'}
Verified: ${_state.user?.isEmailVerified ?? false}
Onboarding: ${_state.user?.onboardingComplete ?? false}
Loading: ${_state.isLoading}
Error: ${_state.error ?? 'None'}
Last Fetch: ${_state.lastFetchTime ?? 'Never'}
    ''');
  }
}
