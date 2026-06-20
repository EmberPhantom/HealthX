import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/models/api_response.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/secure_storage_service.dart';

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

class AuthService {
  static final AuthService _instance = AuthService._internal();
  final DioClient _dioClient = DioClient();
  final SecureStorage _secureStorage = SecureStorage();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  Future<bool> get isAuthenticated async {
    return await _secureStorage.isAuthenticated();
  }

  Future<String?> get accessToken async {
    return await _secureStorage.getToken();
  }

  Future<String?> get refreshToken async {
    return await _secureStorage.getRefreshToken();
  }

  ApiResponse<T> _parseResponse<T>(Response response, T Function(dynamic) fromJson) {
    try {
      dynamic rawData = response.data;
      if (rawData is Map && rawData.containsKey('data')) {
        rawData = rawData['data'];
      }
      final data = fromJson(rawData);
      return ApiResponse<T>.success(
        data: data,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<T>.error(
        error: 'Failed to parse response: $e',
        statusCode: response.statusCode ?? 500,
      );
    }
  }

  AuthException _handleError(dynamic error, String defaultMessage) {
    if (error is AuthException) return error;

    if (error is DioException) {
      int statusCode = error.response?.statusCode ?? 500;
      String message = defaultMessage;

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return AuthException(
          message: ErrorMessages.networkTimeout,
          code: 'NETWORK_TIMEOUT',
          originalError: error,
        );
      } else if (error.type == DioExceptionType.connectionError) {
        return AuthException(
          message: ErrorMessages.noConnection,
          code: 'NO_CONNECTION',
          originalError: error,
        );
      } else if (error.response?.data is Map) {
        final resData = error.response!.data as Map;
        message = resData['message'] ?? resData['error'] ?? message;
      }
      return AuthException(
        message: message,
        code: 'API_ERROR_$statusCode',
        originalError: error,
      );
    }

    return AuthException(
      message: defaultMessage,
      code: 'UNKNOWN_ERROR',
      originalError: error,
    );
  }

  Future<AuthResponse> signup({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'name': name,
        'email': email,
        'password': password,
      };
      if (phone != null && phone.isNotEmpty) body['phone'] = phone;

      debugPrint('📝 Registering: $email');
      final response = await _dioClient.post(AuthEndpoints.signup, data: body);
      final apiResponse = _parseResponse(response, AuthResponse.fromJson);

      if (!apiResponse.isSuccess || apiResponse.data == null) {
        throw AuthException(
          message: apiResponse.errorMessage ?? 'Registration failed',
          code: 'SIGNUP_FAILED',
        );
      }

      await _dioClient.saveAuthTokens(
        apiResponse.data!.accessToken,
        apiResponse.data!.refreshToken,
      );
      await _dioClient.setAuthToken(apiResponse.data!.accessToken);

      return apiResponse.data!;
    } catch (e) {
      throw _handleError(e, 'Registration failed');
    }
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔐 Logging in: $email');
      final response = await _dioClient.post(
        AuthEndpoints.login,
        data: {'email': email, 'password': password},
      );
      final apiResponse = _parseResponse(response, AuthResponse.fromJson);

      if (!apiResponse.isSuccess || apiResponse.data == null) {
        throw AuthException(
          message: apiResponse.errorMessage ?? 'Login failed',
          code: 'LOGIN_FAILED',
        );
      }

      await _dioClient.saveAuthTokens(
        apiResponse.data!.accessToken,
        apiResponse.data!.refreshToken,
      );
      await _dioClient.setAuthToken(apiResponse.data!.accessToken);

      return apiResponse.data!;
    } catch (e) {
      throw _handleError(e, 'Login failed');
    }
  }

  Future<void> logout() async {
    try {
      debugPrint('🚪 Logging out');
      final refreshToken = await _secureStorage.getRefreshToken();
      await _dioClient.post(
        AuthEndpoints.logout,
        data: refreshToken != null ? {'refreshToken': refreshToken} : {},
      );
    } catch (e) {
      debugPrint('⚠️ Logout API call failed: $e');
    } finally {
      try {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.signOut();
        }
      } catch (ge) {
        debugPrint('⚠️ Google signout failed: $ge');
      }
      await _dioClient.clearAllTokens();
      debugPrint('✅ Local tokens cleared');
    }
  }

  Future<String?> signInWithGoogle({bool forceAccountSelection = false}) async {
    try {
      debugPrint('🔵 Starting Google Sign-in flow');
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      if (forceAccountSelection) {
        await googleSignIn.signOut();
      }

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('⚠️ Google Sign-in cancelled by user');
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw AuthException(
          message: 'Failed to obtain Google ID token',
          code: 'ID_TOKEN_MISSING',
        );
      }
      return idToken;
    } catch (e) {
      throw _handleError(e, 'Google Sign-in failed');
    }
  }

  Future<AuthResponse> googleLogin({required String idToken}) async {
    try {
      debugPrint('🔵 Google login with ID token');
      final response = await _dioClient.post(
        AuthEndpoints.googleAuth,
        data: {'idToken': idToken},
      );
      final apiResponse = _parseResponse(response, AuthResponse.fromJson);

      if (!apiResponse.isSuccess || apiResponse.data == null) {
        throw AuthException(
          message: apiResponse.errorMessage ?? 'Google login failed',
          code: 'GOOGLE_LOGIN_FAILED',
        );
      }

      await _dioClient.saveAuthTokens(
        apiResponse.data!.accessToken,
        apiResponse.data!.refreshToken,
      );
      await _dioClient.setAuthToken(apiResponse.data!.accessToken);

      return apiResponse.data!;
    } catch (e) {
      throw _handleError(e, 'Google login failed');
    }
  }

  Future<UserProfile> completeOnboarding({
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
    try {
      debugPrint('📋 Completing onboarding on backend');
      final response = await _dioClient.post(
        OnboardingEndpoints.completeOnboarding,
        data: {
          if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
          if (phone != null) 'phone': phone,
          if (gender != null) 'gender': gender,
          if (avatarUrl != null) 'avatarUrl': avatarUrl,
          if (medicalHistory != null) 'medicalHistory': medicalHistory,
          if (allergies != null) 'allergies': allergies,
          if (medications != null) 'medications': medications,
          if (emergencyContactName != null) 'emergencyContactName': emergencyContactName,
          if (emergencyContactPhone != null) 'emergencyContactPhone': emergencyContactPhone,
          if (insuranceProvider != null) 'insuranceProvider': insuranceProvider,
          if (insurancePolicyNumber != null) 'insurancePolicyNo': insurancePolicyNumber,
          if (height != null) 'height': height,
          if (weight != null) 'weight': weight,
          if (isDiabetesPatient != null) 'isDiabetesPatient': isDiabetesPatient,
          if (isBpPatient != null) 'isBpPatient': isBpPatient,
          if (wellnessGoals != null) 'wellnessGoals': wellnessGoals,
          if (dominantDosha != null) 'dominantDosha': dominantDosha,
          if (activityLevel != null) 'activityLevel': activityLevel,
          if (age != null) 'age': age,
        },
      );

      dynamic rawData = response.data;
      if (rawData is Map && rawData.containsKey('data')) {
        rawData = rawData['data'];
      }
      final userProfile = UserProfile.fromJson(rawData['user'] ?? rawData);
      return userProfile;
    } catch (e) {
      throw _handleError(e, 'Failed to complete onboarding');
    }
  }

  Future<UserProfile> getCurrentUser() async {
    try {
      final response = await _dioClient.get(UserEndpoints.getProfile);
      dynamic rawData = response.data;
      if (rawData is Map && rawData.containsKey('data')) {
        rawData = rawData['data'];
      }
      return UserProfile.fromJson(rawData);
    } catch (e) {
      throw _handleError(e, 'Failed to fetch user profile');
    }
  }

  Future<List<String>> toggleFavorite(String itemId) async {
    try {
      final response = await _dioClient.post(
        UserEndpoints.toggleFavorite,
        data: {'itemId': itemId},
      );
      dynamic rawData = response.data;
      if (rawData is Map && rawData.containsKey('data')) {
        rawData = rawData['data'];
      }
      return List<String>.from(rawData['favorites'] ?? []);
    } catch (e) {
      throw _handleError(e, 'Failed to toggle favorite');
    }
  }

  Future<UserProfile> updateProfile({
    String? name,
    String? phone,
    String? gender,
    int? age,
    String? avatarUrl,
  }) async {
    try {
      final response = await _dioClient.put(
        UserEndpoints.updateProfile,
        data: {
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
          if (gender != null) 'gender': gender,
          if (age != null) 'age': age,
          if (avatarUrl != null) 'avatarUrl': avatarUrl,
        },
      );
      dynamic rawData = response.data;
      if (rawData is Map && rawData.containsKey('data')) {
        rawData = rawData['data'];
      }
      return UserProfile.fromJson(rawData);
    } catch (e) {
      throw _handleError(e, 'Failed to update profile');
    }
  }

  Future<UserProfile> updateSettings({
    int? dailyWaterGoalMl,
    int? dailyStepGoal,
    int? dailyCalorieGoal,
    int? dailyProteinGoalG,
    int? dailyCarbGoalG,
    int? dailyFatGoalG,
    bool? reminderEnabled,
  }) async {
    try {
      debugPrint('⚙️ Updating settings on backend');
      await _dioClient.put(
        UserEndpoints.updateSettings,
        data: {
          if (dailyWaterGoalMl != null) 'dailyWaterGoalMl': dailyWaterGoalMl,
          if (dailyStepGoal != null) 'dailyStepGoal': dailyStepGoal,
          if (dailyCalorieGoal != null) 'dailyCalorieGoal': dailyCalorieGoal,
          if (dailyProteinGoalG != null) 'dailyProteinGoalG': dailyProteinGoalG,
          if (dailyCarbGoalG != null) 'dailyCarbGoalG': dailyCarbGoalG,
          if (dailyFatGoalG != null) 'dailyFatGoalG': dailyFatGoalG,
          if (reminderEnabled != null) 'reminderEnabled': reminderEnabled,
        },
      );
      return await getCurrentUser();
    } catch (e) {
      throw _handleError(e, 'Failed to update settings');
    }
  }

  Future<String> uploadProfilePicture({required String imagePath}) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(imagePath),
      });

      final response = await _dioClient.post(
        AuthEndpoints.uploadProfilePicture,
        data: formData,
      );

      dynamic rawData = response.data;
      if (rawData is Map && rawData.containsKey('data')) {
        rawData = rawData['data'];
      }
      // Backend returns { avatarUrl: string, user: {...} }
      if (rawData is Map) {
        return rawData['avatarUrl'] as String? ?? '';
      }
      return rawData.toString();
    } catch (e) {
      throw _handleError(e, 'Failed to upload profile picture');
    }
  }

  Future<void> forgotPassword({required String email}) async {
    try {
      await _dioClient.post(
        AuthEndpoints.forgotPassword,
        data: {'email': email},
      );
    } catch (e) {
      throw _handleError(e, 'Failed to send password reset email');
    }
  }

  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    try {
      await _dioClient.post(
        AuthEndpoints.resetPassword,
        data: {'token': token, 'password': password},
      );
    } catch (e) {
      throw _handleError(e, 'Failed to reset password');
    }
  }

  Future<bool> deleteAccount() async {
    try {
      final response = await _dioClient.delete(UserEndpoints.updateProfile);
      await _dioClient.clearAllTokens();
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('❌ deleteAccount failed: $e');
      return false;
    }
  }

  Future<UserProfile?> restoreSession() async {
    final token = await _secureStorage.getToken();
    if (token == null) return null;

    try {
      final profile = await getCurrentUser().timeout(const Duration(seconds: 3));
      return profile;
    } on TimeoutException catch (_) {
      debugPrint('⚠️ Restore session timed out');
      return null;
    } on AuthException catch (e) {
      final isNetwork = e.code == 'NETWORK_TIMEOUT' || e.code == 'NO_CONNECTION';
      if (isNetwork) return null; // Keep token for retry

      await _secureStorage.clearAllTokens();
      return null;
    } catch (_) {
      return null;
    }
  }
}
