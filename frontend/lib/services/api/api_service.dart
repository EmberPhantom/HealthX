/// API Service Layer
/// Provides all backend API endpoints as callable methods
/// Wraps DioClient and handles response parsing

import 'package:dio/dio.dart';
import '../../models/api/api_response.dart';
import '../../models/api/auth_models.dart';
import '../../models/models.dart' hide UserProfile;
import 'api_constants.dart';
import 'dio_client.dart';

/// Central API service for all backend operations
class ApiService {
  static ApiService _instance = ApiService._internal();
  final DioClient _dioClient = DioClient();

  Future<ApiResponse<Map<String, dynamic>>>? _settingsFuture;
  DateTime? _lastSettingsFetchTime;
  ApiResponse<Map<String, dynamic>>? _cachedSettings;

  factory ApiService() {
    return _instance;
  }

  static set instance(ApiService mock) => _instance = mock;

  ApiService._internal();

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Handle Dio exception and convert to ApiResponse error
  ApiResponse<T> _handleError<T>(DioException error) {
    int statusCode = error.response?.statusCode ?? 500;
    String message = ErrorMessages.somethingWentWrong;

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      statusCode = 0;
      message = ErrorMessages.networkTimeout;
    } else if (error.type == DioExceptionType.connectionError) {
      statusCode = -1;
      message = ErrorMessages.noConnection;
    } else if (error.response?.data is Map) {
      final data = error.response!.data as Map;
      message = data['message'] ?? data['error'] ?? message;
    }

    return ApiResponse<T>.error(
      error: message,
      statusCode: statusCode,
    );
  }

  /// Extract data from successful response and return typed ApiResponse
  /// Handles the { statusCode, status, message, data: {...} } envelope
  ApiResponse<T> _parseResponse<T>(
    Response response,
    T Function(dynamic)? fromJson,
  ) {
    try {
      // Unwrap the data envelope: { statusCode, status, message, data }
      dynamic rawData = response.data;
      if (rawData is Map && rawData.containsKey('data')) {
        rawData = rawData['data'];
      }

      if (fromJson != null) {
        final data = fromJson(rawData);
        return ApiResponse<T>.success(
          data: data,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse<T>.success(
          data: rawData as T,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<T>.error(
        error: 'Failed to parse response: $e',
        statusCode: response.statusCode ?? 500,
      );
    }
  }

  // ============================================================================
  // AUTHENTICATION ENDPOINTS
  // ============================================================================

  /// POST /auth/signup
  Future<ApiResponse<AuthResponse>> signup({
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

      final response = await _dioClient.post(
        AuthEndpoints.signup,
        data: body,
      );

      final apiResponse = _parseResponse(response, AuthResponse.fromJson);

      // Save tokens on success
      if (apiResponse.isSuccess && apiResponse.data != null) {
        await _dioClient.saveAuthTokens(
          apiResponse.data!.accessToken,
          apiResponse.data!.refreshToken,
        );
        await _dioClient.setAuthToken(apiResponse.data!.accessToken);
      }

      return apiResponse;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// POST /auth/login
  Future<ApiResponse<AuthResponse>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dioClient.post(
        AuthEndpoints.login,
        data: {'email': email, 'password': password},
      );

      final apiResponse = _parseResponse(response, AuthResponse.fromJson);

      // Save tokens on success
      if (apiResponse.isSuccess && apiResponse.data != null) {
        await _dioClient.saveAuthTokens(
          apiResponse.data!.accessToken,
          apiResponse.data!.refreshToken,
        );
        await _dioClient.setAuthToken(apiResponse.data!.accessToken);
      }

      return apiResponse;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// POST /auth/logout
  Future<ApiResponse<EmptyResponse>> logout() async {
    try {
      // Get the refresh token to send in body
      final refreshToken = await _dioClient.getRefreshToken();
      final response = await _dioClient.post(
        AuthEndpoints.logout,
        data: refreshToken != null ? {'refreshToken': refreshToken} : {},
      );

      // Clear tokens regardless of response
      await _dioClient.clearAllTokens();

      return _parseResponse(
          response, (_) => const EmptyResponse(success: true));
    } on DioException catch (e) {
      // Clear tokens even on error — graceful logout
      await _dioClient.clearAllTokens();
      return _handleError(e);
    }
  }

  /// POST /auth/refresh
  Future<ApiResponse<TokenRefreshResponse>> refreshToken({
    required String refreshToken,
  }) async {
    try {
      final response = await _dioClient.post(
        AuthEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      final apiResponse =
          _parseResponse(response, TokenRefreshResponse.fromJson);

      // Update stored access token on success
      if (apiResponse.isSuccess && apiResponse.data != null) {
        await _dioClient.setAuthToken(apiResponse.data!.accessToken);
      }

      return apiResponse;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// POST /auth/google
  /// Send Firebase/Google ID token for server-side verification
  Future<ApiResponse<AuthResponse>> googleLogin({
    required String idToken,
  }) async {
    try {
      final response = await _dioClient.post(
        AuthEndpoints.googleAuth,
        data: {'idToken': idToken},
      );

      final apiResponse = _parseResponse(response, AuthResponse.fromJson);

      // Save tokens on success
      if (apiResponse.isSuccess && apiResponse.data != null) {
        await _dioClient.saveAuthTokens(
          apiResponse.data!.accessToken,
          apiResponse.data!.refreshToken,
        );
        await _dioClient.setAuthToken(apiResponse.data!.accessToken);
      }

      return apiResponse;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ============================================================================
  // ONBOARDING ENDPOINTS
  // ============================================================================

  /// POST /onboarding/verify-email
  Future<ApiResponse<EmptyResponse>> verifyEmail({
    required String token,
  }) async {
    try {
      final response = await _dioClient.post(
        OnboardingEndpoints.verifyEmail,
        data: {'token': token},
      );
      return _parseResponse(
          response, (_) => const EmptyResponse(success: true));
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// POST /onboarding/resend-verification
  Future<ApiResponse<EmptyResponse>> resendVerification() async {
    try {
      final response =
          await _dioClient.post(OnboardingEndpoints.resendVerification);
      return _parseResponse(
          response, (_) => const EmptyResponse(success: true));
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// POST /onboarding/complete
  Future<ApiResponse<UserProfile>> completeOnboarding({
    String? dateOfBirth,
    String? phone,
    String? gender,
    String? medicalHistory,
    List<String>? allergies,
    String? insuranceProvider,
    String? insurancePolicyNumber,
  }) async {
    try {
      final response = await _dioClient.post(
        OnboardingEndpoints.completeOnboarding,
        data: {
          if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
          if (phone != null) 'phone': phone,
          if (gender != null) 'gender': gender,
          if (medicalHistory != null) 'medicalHistory': medicalHistory,
          if (allergies != null) 'allergies': allergies,
          if (insuranceProvider != null) 'insuranceProvider': insuranceProvider,
          if (insurancePolicyNumber != null)
            'insurancePolicyNumber': insurancePolicyNumber,
        },
      );
      return _parseResponse(
          response, (data) => UserProfile.fromJson(data['user'] ?? data));
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// GET /onboarding/status
  Future<ApiResponse<OnboardingStatus>> getOnboardingStatus() async {
    try {
      final response =
          await _dioClient.get(OnboardingEndpoints.onboardingStatus);
      return _parseResponse(
          response, (data) => OnboardingStatus.fromJson(data));
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ============================================================================
  // USER ENDPOINTS
  // ============================================================================

  /// GET /users/me — Get current user profile
  Future<ApiResponse<UserProfile>> getProfile() async {
    try {
      final response = await _dioClient.get(UserEndpoints.getProfile);
      return _parseResponse(
          response, (data) => UserProfile.fromJson(data));
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// PUT /users/me — Update user profile
  Future<ApiResponse<UserProfile>> updateProfile({
    String? name,
    String? phone,
    String? gender,
    int? age,
  }) async {
    try {
      final response = await _dioClient.put(
        UserEndpoints.updateProfile,
        data: {
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
          if (gender != null) 'gender': gender,
          if (age != null) 'age': age,
        },
      );
      return _parseResponse(
          response, (data) => UserProfile.fromJson(data));
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// POST /auth/me/upload-picture — Upload profile picture
  Future<ApiResponse<StringResponse>> uploadProfilePicture({
    required String imagePath,
    ProgressCallback? onProgress,
  }) async {
    try {
      final response = await _dioClient.uploadFile(
        AuthEndpoints.uploadProfilePicture,
        fileKey: 'file', // matches multer .single('file') on backend
        filePath: imagePath,
        onProgress: onProgress,
      );

      return _parseResponse(
        response,
        (data) {
          // Backend returns { avatarUrl: "..." } in data
          final url = data is Map ? (data['avatarUrl'] ?? data['url'] ?? '') : '';
          return StringResponse(url.toString());
        },
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ============================================================================
  // SECURITY ENDPOINTS
  // ============================================================================

  /// POST /security/csrf-token
  Future<ApiResponse<TokenResponse>> getCsrfToken() async {
    try {
      final response =
          await _dioClient.post(SecurityEndpoints.getCsrfToken);
      return _parseResponse(response, (data) => TokenResponse.fromJson(data));
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// GET /security/login-history
  Future<ApiResponse<PaginatedResponse<Map>>> getLoginHistory({
    int? limit,
    int? offset,
  }) async {
    try {
      final response = await _dioClient.get(
        SecurityEndpoints.getLoginHistory,
        queryParameters: {
          if (limit != null) 'limit': limit,
          if (offset != null) 'offset': offset,
        },
      );
      return _parseResponse(
        response,
        (data) => PaginatedResponse<Map>.fromJson(data, (item) => item as Map),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// GET /security/suspicious-activity
  Future<ApiResponse<List<Map>>> getSuspiciousActivity() async {
    try {
      final response =
          await _dioClient.get(SecurityEndpoints.getSuspiciousActivity);
      return _parseResponse(
        response,
        (data) => (data as List).map((item) => item as Map).toList(),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// POST /security/clear-failed-attempts
  Future<ApiResponse<EmptyResponse>> clearFailedAttempts() async {
    try {
      final response =
          await _dioClient.post(SecurityEndpoints.clearFailedAttempts);
      return _parseResponse(
          response, (_) => const EmptyResponse(success: true));
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// GET /security/audit-logs
  Future<ApiResponse<PaginatedResponse<Map>>> getAuditLogs({
    int? limit,
    int? offset,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await _dioClient.get(
        SecurityEndpoints.getAuditLogs,
        queryParameters: {
          if (limit != null) 'limit': limit,
          if (offset != null) 'offset': offset,
          if (startDate != null) 'startDate': startDate,
          if (endDate != null) 'endDate': endDate,
        },
      );
      return _parseResponse(
        response,
        (data) => PaginatedResponse<Map>.fromJson(data, (item) => item as Map),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// GET /content/categories
  Future<ApiResponse<List<MenuCategory>>> getCategories() async {
    try {
      final response = await _dioClient.get(ContentEndpoints.categories);
      return _parseResponse(
        response,
        (data) => (data as List).map((x) => MenuCategory.fromJson(x as Map<String, dynamic>)).toList(),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// GET /content/banners
  Future<ApiResponse<List<BannerModel>>> getBanners() async {
    try {
      final response = await _dioClient.get(ContentEndpoints.banners);
      return _parseResponse(
        response,
        (data) => (data as List).map((x) => BannerModel.fromJson(x as Map<String, dynamic>)).toList(),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// GET /content/meal-plans
  Future<ApiResponse<List<MealPlan>>> getMealPlans() async {
    try {
      final response = await _dioClient.get(ContentEndpoints.mealPlans);
      return _parseResponse(
        response,
        (data) => (data as List).map((x) => MealPlan.fromJson(x as Map<String, dynamic>)).toList(),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// GET /content/menu-items
  Future<ApiResponse<List<MenuItem>>> getMenuItems({String? type}) async {
    try {
      final response = await _dioClient.get(
        ContentEndpoints.menuItems,
        queryParameters: {
          if (type != null) 'type': type,
        },
      );
      return _parseResponse(
        response,
        (data) => (data as List).map((x) => MenuItem.fromJson(x as Map<String, dynamic>)).toList(),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ============================================================================
  // MEAL ENDPOINTS
  // ============================================================================

  /// POST /meals/identify
  Future<ApiResponse<Map<String, dynamic>>> identifyMeal({
    String? text,
    String? imageUrl,
  }) async {
    try {
      final response = await _dioClient.post(
        MealEndpoints.identify,
        data: {
          if (text != null) 'text': text,
          if (imageUrl != null) 'imageUrl': imageUrl,
        },
      );
      return _parseResponse(response, (data) => data as Map<String, dynamic>);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// POST /meals/identify-image
  Future<ApiResponse<Map<String, dynamic>>> identifyMealFromImage({
    required String imagePath,
    ProgressCallback? onProgress,
  }) async {
    try {
      final response = await _dioClient.uploadFile(
        MealEndpoints.identifyImage,
        fileKey: 'image',
        filePath: imagePath,
        onProgress: onProgress,
      );
      return _parseResponse(response, (data) => data as Map<String, dynamic>);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// POST /meals/log
  Future<ApiResponse<Map<String, dynamic>>> logMeal(Map<String, dynamic> mealData) async {
    try {
      final response = await _dioClient.post(
        MealEndpoints.log,
        data: mealData,
      );
      return _parseResponse(response, (data) => data as Map<String, dynamic>);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// GET /meals
  Future<ApiResponse<List<Map<String, dynamic>>>> getMeals(DateTime date) async {
    try {
      final response = await _dioClient.get(
        MealEndpoints.getMeals,
        queryParameters: {'date': date.toIso8601String()},
      );
      return _parseResponse(
        response,
        (data) => (data as List).map((x) => x as Map<String, dynamic>).toList(),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// DELETE /meals/:id
  Future<ApiResponse<EmptyResponse>> deleteMeal(String id) async {
    try {
      final response = await _dioClient.delete(MealEndpoints.delete(id));
      return _parseResponse(
          response, (_) => const EmptyResponse(success: true));
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ============================================================================
  // TRACKER ENDPOINTS
  // ============================================================================

  /// POST /trackers/water
  Future<ApiResponse<Map<String, dynamic>>> logWater({
    required double amount,
    DateTime? date,
  }) async {
    try {
      final response = await _dioClient.post(
        TrackerEndpoints.logWater,
        data: {
          'amount': amount,
          if (date != null) 'date': date.toIso8601String(),
        },
      );
      return _parseResponse(response, (data) => data as Map<String, dynamic>);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// GET /trackers/water
  Future<ApiResponse<List<Map<String, dynamic>>>> getWaterLogs({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _dioClient.get(
        TrackerEndpoints.getWater,
        queryParameters: {
          if (startDate != null) 'startDate': startDate.toIso8601String(),
          if (endDate != null) 'endDate': endDate.toIso8601String(),
        },
      );
      return _parseResponse(
        response,
        (data) => (data as List).map((x) => x as Map<String, dynamic>).toList(),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// POST /trackers/sleep
  Future<ApiResponse<Map<String, dynamic>>> logSleep({
    required DateTime bedtime,
    required DateTime wakeTime,
    required String dateKey,
  }) async {
    try {
      final response = await _dioClient.post(
        TrackerEndpoints.logSleep,
        data: {
          'bedtime': bedtime.toIso8601String(),
          'wakeTime': wakeTime.toIso8601String(),
          'dateKey': dateKey,
        },
      );
      return _parseResponse(response, (data) => data as Map<String, dynamic>);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// GET /trackers/sleep
  Future<ApiResponse<List<Map<String, dynamic>>>> getSleepLogs() async {
    try {
      final response = await _dioClient.get(TrackerEndpoints.getSleep);
      return _parseResponse(
        response,
        (data) => (data as List).map((x) => x as Map<String, dynamic>).toList(),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// POST /trackers/steps
  Future<ApiResponse<Map<String, dynamic>>> logSteps({
    required int steps,
    required String dateKey,
  }) async {
    try {
      final response = await _dioClient.post(
        TrackerEndpoints.logSteps,
        data: {
          'steps': steps,
          'dateKey': dateKey,
        },
      );
      return _parseResponse(response, (data) => data as Map<String, dynamic>);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// GET /trackers/steps
  Future<ApiResponse<List<Map<String, dynamic>>>> getStepLogs({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await _dioClient.get(
        TrackerEndpoints.getSteps,
        queryParameters: {
          if (startDate != null) 'startDate': startDate,
          if (endDate != null) 'endDate': endDate,
        },
      );
      return _parseResponse(
        response,
        (data) => (data as List).map((x) => x as Map<String, dynamic>).toList(),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ============================================================================
  // USER STATS ENDPOINTS
  // ============================================================================

  /// GET /users/me/stats
  Future<ApiResponse<Map<String, dynamic>>> getProfileStats() async {
    try {
      final response = await _dioClient.get(UserEndpoints.getStats);
      return _parseResponse(response, (data) => data as Map<String, dynamic>);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ============================================================================
  // NOTIFICATION ENDPOINTS
  // ============================================================================

  /// GET /notifications
  Future<ApiResponse<List<Map<String, dynamic>>>> getNotifications() async {
    try {
      final response = await _dioClient.get(NotificationEndpoints.base);
      return _parseResponse(
        response,
        (data) => (data as List).map((x) => x as Map<String, dynamic>).toList(),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// PATCH /notifications/:id/read
  Future<ApiResponse<Map<String, dynamic>>> markNotificationAsRead(String id) async {
    try {
      final response = await _dioClient.patch(NotificationEndpoints.markAsRead(id));
      return _parseResponse(response, (data) => data as Map<String, dynamic>);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// DELETE /notifications/:id
  Future<ApiResponse<EmptyResponse>> deleteNotification(String id) async {
    try {
      final response = await _dioClient.delete(NotificationEndpoints.delete(id));
      return _parseResponse(
          response, (_) => const EmptyResponse(success: true));
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ============================================================================
  // PIPELINE ENDPOINTS
  // ============================================================================

  /// POST /users/me/favorites/toggle
  Future<ApiResponse<Map<String, dynamic>>> toggleFavorite(String itemId) async {
    try {
      final response = await _dioClient.post(
        UserEndpoints.toggleFavorite,
        data: {'itemId': itemId},
      );
      return _parseResponse(response, (data) => data as Map<String, dynamic>);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// PUT /users/me/wellness-goals
  Future<ApiResponse<Map<String, dynamic>>> updateWellnessGoals(List<String> goals) async {
    try {
      final response = await _dioClient.put(
        UserEndpoints.updateWellnessGoals,
        data: {'goals': goals},
      );
      return _parseResponse(response, (data) => data as Map<String, dynamic>);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// POST /users/me/rating
  Future<ApiResponse<Map<String, dynamic>>> setAppRating(int rating) async {
    try {
      final response = await _dioClient.post(
        UserEndpoints.setRating,
        data: {'rating': rating},
      );
      return _parseResponse(response, (data) => data as Map<String, dynamic>);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// PATCH /users/me/points
  Future<ApiResponse<Map<String, dynamic>>> updatePoints(int points) async {
    try {
      final response = await _dioClient.patch(
        UserEndpoints.updatePoints,
        data: {'points': points},
      );
      return _parseResponse(response, (data) => data as Map<String, dynamic>);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// GET /users/me/settings
  Future<ApiResponse<Map<String, dynamic>>> getUserSettings() async {
    final now = DateTime.now();
    if (_cachedSettings != null &&
        _lastSettingsFetchTime != null &&
        now.difference(_lastSettingsFetchTime!) < const Duration(seconds: 10)) {
      return _cachedSettings!;
    }
    if (_settingsFuture != null) {
      return _settingsFuture!;
    }
    _settingsFuture = () async {
      try {
        final response = await _dioClient.get(UserEndpoints.getSettings);
        final parsed = _parseResponse(response, (data) => data as Map<String, dynamic>);
        if (parsed.success) {
          _cachedSettings = parsed;
          _lastSettingsFetchTime = DateTime.now();
        }
        return parsed;
      } on DioException catch (e) {
        return _handleError<Map<String, dynamic>>(e);
      } finally {
        _settingsFuture = null;
      }
    }();
    return _settingsFuture!;
  }

  /// PUT /users/me/settings
  Future<ApiResponse<Map<String, dynamic>>> updateUserSettings(Map<String, dynamic> settings) async {
    try {
      final response = await _dioClient.put(
        UserEndpoints.updateSettings,
        data: settings,
      );
      final parsed = _parseResponse(response, (data) => data as Map<String, dynamic>);
      if (parsed.success) {
        _cachedSettings = parsed;
        _lastSettingsFetchTime = DateTime.now();
      }
      return parsed;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ============================================================================
  // MEDICAL TRACKER ENDPOINTS
  // ============================================================================

  /// POST /trackers/vitals
  Future<ApiResponse<Map<String, dynamic>>> logVitals(Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.post(TrackerEndpoints.logVitals, data: data);
      return _parseResponse(response, (d) => d as Map<String, dynamic>);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// GET /trackers/vitals
  Future<ApiResponse<List<Map<String, dynamic>>>> getVitals() async {
    try {
      final response = await _dioClient.get(TrackerEndpoints.getVitals);
      return _parseResponse(
        response,
        (data) => (data as List).map((x) => x as Map<String, dynamic>).toList(),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// DELETE /trackers/vitals/:id
  Future<ApiResponse<EmptyResponse>> deleteVitals(String id) async {
    try {
      final response = await _dioClient.delete(TrackerEndpoints.deleteVitals(id));
      return _parseResponse(response, (_) => const EmptyResponse(success: true));
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// POST /trackers/glucose
  Future<ApiResponse<Map<String, dynamic>>> logGlucose(Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.post(TrackerEndpoints.logGlucose, data: data);
      return _parseResponse(response, (d) => d as Map<String, dynamic>);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// GET /trackers/glucose
  Future<ApiResponse<List<Map<String, dynamic>>>> getGlucose() async {
    try {
      final response = await _dioClient.get(TrackerEndpoints.getGlucose);
      return _parseResponse(
        response,
        (data) => (data as List).map((x) => x as Map<String, dynamic>).toList(),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// DELETE /trackers/glucose/:id
  Future<ApiResponse<EmptyResponse>> deleteGlucose(String id) async {
    try {
      final response = await _dioClient.delete(TrackerEndpoints.deleteGlucose(id));
      return _parseResponse(response, (_) => const EmptyResponse(success: true));
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// POST /trackers/insulin
  Future<ApiResponse<Map<String, dynamic>>> logInsulin(Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.post(TrackerEndpoints.logInsulin, data: data);
      return _parseResponse(response, (d) => d as Map<String, dynamic>);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// GET /trackers/insulin
  Future<ApiResponse<List<Map<String, dynamic>>>> getInsulin() async {
    try {
      final response = await _dioClient.get(TrackerEndpoints.getInsulin);
      return _parseResponse(
        response,
        (data) => (data as List).map((x) => x as Map<String, dynamic>).toList(),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// DELETE /trackers/insulin/:id
  Future<ApiResponse<EmptyResponse>> deleteInsulin(String id) async {
    try {
      final response = await _dioClient.delete(TrackerEndpoints.deleteInsulin(id));
      return _parseResponse(response, (_) => const EmptyResponse(success: true));
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// POST /trackers/measurements
  Future<ApiResponse<Map<String, dynamic>>> logMeasurement(Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.post(TrackerEndpoints.logMeasurement, data: data);
      return _parseResponse(response, (d) => d as Map<String, dynamic>);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// GET /trackers/measurements
  Future<ApiResponse<List<Map<String, dynamic>>>> getMeasurements() async {
    try {
      final response = await _dioClient.get(TrackerEndpoints.getMeasurements);
      return _parseResponse(
        response,
        (data) => (data as List).map((x) => x as Map<String, dynamic>).toList(),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// DELETE /trackers/measurements/:id
  Future<ApiResponse<EmptyResponse>> deleteMeasurement(String id) async {
    try {
      final response = await _dioClient.delete(TrackerEndpoints.deleteMeasurement(id));
      return _parseResponse(response, (_) => const EmptyResponse(success: true));
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ============================================================================
  // ADDRESS ENDPOINTS
  // ============================================================================

  /// GET /addresses
  Future<ApiResponse<List<Map<String, dynamic>>>> getAddresses() async {
    try {
      final response = await _dioClient.get(AddressEndpoints.base);
      return _parseResponse(
        response,
        (data) => (data as List).map((x) => x as Map<String, dynamic>).toList(),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// POST /addresses
  Future<ApiResponse<Map<String, dynamic>>> createAddress(Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.post(AddressEndpoints.base, data: data);
      return _parseResponse(response, (d) => d as Map<String, dynamic>);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// PUT /addresses/:id
  Future<ApiResponse<Map<String, dynamic>>> updateAddress(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.put(AddressEndpoints.update(id), data: data);
      return _parseResponse(response, (d) => d as Map<String, dynamic>);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// DELETE /addresses/:id
  Future<ApiResponse<EmptyResponse>> deleteAddress(String id) async {
    try {
      final response = await _dioClient.delete(AddressEndpoints.delete(id));
      return _parseResponse(response, (_) => const EmptyResponse(success: true));
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// PATCH /addresses/:id/default
  Future<ApiResponse<Map<String, dynamic>>> setDefaultAddress(String id) async {
    try {
      final response = await _dioClient.patch(AddressEndpoints.setDefault(id));
      return _parseResponse(response, (d) => d as Map<String, dynamic>);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ============================================================================
  // ORDER ENDPOINTS
  // ============================================================================

  /// POST /orders
  Future<ApiResponse<Map<String, dynamic>>> placeOrder(Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.post(OrderEndpoints.base, data: data);
      return _parseResponse(response, (d) => d as Map<String, dynamic>);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// GET /orders
  Future<ApiResponse<List<Map<String, dynamic>>>> getOrders() async {
    try {
      final response = await _dioClient.get(OrderEndpoints.base);
      return _parseResponse(
        response,
        (data) => (data as List).map((x) => x as Map<String, dynamic>).toList(),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// GET /orders/:id
  Future<ApiResponse<Map<String, dynamic>>> getOrder(String id) async {
    try {
      final response = await _dioClient.get(OrderEndpoints.getOne(id));
      return _parseResponse(response, (d) => d as Map<String, dynamic>);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// POST /orders/:id/cancel
  Future<ApiResponse<Map<String, dynamic>>> cancelOrder(String id, {String? cancelReason}) async {
    try {
      final response = await _dioClient.post(
        OrderEndpoints.cancel(id),
        data: {if (cancelReason != null) 'cancelReason': cancelReason},
      );
      return _parseResponse(response, (d) => d as Map<String, dynamic>);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// GET /orders/:id/status
  Future<ApiResponse<Map<String, dynamic>>> getOrderStatus(String id) async {
    try {
      final response = await _dioClient.get(OrderEndpoints.status(id));
      return _parseResponse(response, (d) => d as Map<String, dynamic>);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ============================================================================
  // DOCTOR & APPOINTMENT ENDPOINTS
  // ============================================================================

  /// GET /doctors
  Future<ApiResponse<List<Map<String, dynamic>>>> getDoctors({String? specialty, String? city}) async {
    try {
      final response = await _dioClient.get(
        DoctorEndpoints.base,
        queryParameters: {
          if (specialty != null) 'specialty': specialty,
          if (city != null) 'city': city,
        },
      );
      return _parseResponse(
        response,
        (data) => (data as List).map((x) => x as Map<String, dynamic>).toList(),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// GET /doctors/:id
  Future<ApiResponse<Map<String, dynamic>>> getDoctor(String id) async {
    try {
      final response = await _dioClient.get(DoctorEndpoints.getOne(id));
      return _parseResponse(response, (d) => d as Map<String, dynamic>);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// GET /doctors/:id/slots
  Future<ApiResponse<List<String>>> getDoctorSlots(String id, DateTime date) async {
    try {
      final response = await _dioClient.get(
        DoctorEndpoints.getSlots(id),
        queryParameters: {'date': date.toIso8601String()},
      );
      return _parseResponse(
        response,
        (data) => (data as List).map((x) => x.toString()).toList(),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// POST /appointments
  Future<ApiResponse<Map<String, dynamic>>> bookAppointment(Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.post(AppointmentEndpoints.base, data: data);
      return _parseResponse(response, (d) => d as Map<String, dynamic>);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// GET /appointments
  Future<ApiResponse<List<Map<String, dynamic>>>> getAppointments() async {
    try {
      final response = await _dioClient.get(AppointmentEndpoints.base);
      return _parseResponse(
        response,
        (data) => (data as List).map((x) => x as Map<String, dynamic>).toList(),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// DELETE /appointments/:id (Cancel)
  Future<ApiResponse<Map<String, dynamic>>> cancelAppointment(String id) async {
    try {
      final response = await _dioClient.delete(AppointmentEndpoints.delete(id));
      return _parseResponse(response, (d) => d as Map<String, dynamic>);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ============================================================================
  // HEALTH RECORD ENDPOINTS
  // ============================================================================

  /// GET /health-records
  Future<ApiResponse<List<Map<String, dynamic>>>> getHealthRecords({
    String? type,
    String? specialist,
  }) async {
    try {
      final response = await _dioClient.get(
        HealthRecordEndpoints.base,
        queryParameters: {
          if (type != null) 'type': type,
          if (specialist != null) 'specialist': specialist,
        },
      );
      return _parseResponse(
        response,
        (data) => (data as List).map((x) => x as Map<String, dynamic>).toList(),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// POST /health-records (upload multiple files)
  Future<ApiResponse<Map<String, dynamic>>> createHealthRecord({
    required String name,
    required String type,
    required String date,
    required String specialist,
    required List<String> filePaths,
    ProgressCallback? onProgress,
  }) async {
    try {
      final multipartFiles = <MultipartFile>[];
      for (final path in filePaths) {
        multipartFiles.add(await MultipartFile.fromFile(path));
      }

      final formData = FormData.fromMap({
        'name': name,
        'type': type,
        'date': date,
        'specialist': specialist,
        'files': multipartFiles,
      });

      final response = await _dioClient.dio.post(
        HealthRecordEndpoints.base,
        data: formData,
        onSendProgress: onProgress,
      );

      return _parseResponse(response, (data) => data as Map<String, dynamic>);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// DELETE /health-records/:id
  Future<ApiResponse<EmptyResponse>> deleteHealthRecord(String id) async {
    try {
      final response = await _dioClient.delete(HealthRecordEndpoints.delete(id));
      return _parseResponse(response, (_) => const EmptyResponse(success: true));
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ============================================================================
  // SUBSCRIPTION ENDPOINTS
  // ============================================================================

  /// POST /subscriptions/subscribe
  Future<ApiResponse<Map<String, dynamic>>> subscribeToPlan(String planId, {String billingPeriod = 'monthly'}) async {
    try {
      final response = await _dioClient.post(
        '/subscriptions/subscribe',
        data: {
          'planId': planId,
          'billingPeriod': billingPeriod,
        },
      );
      return _parseResponse(response, (d) => d as Map<String, dynamic>);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// POST /subscriptions/pause/:id
  Future<ApiResponse<Map<String, dynamic>>> pauseSubscription(String id) async {
    try {
      final response = await _dioClient.post('/subscriptions/pause/$id');
      return _parseResponse(response, (d) => d as Map<String, dynamic>);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// POST /subscriptions/cancel/:id
  Future<ApiResponse<Map<String, dynamic>>> cancelSubscription(String id) async {
    try {
      final response = await _dioClient.post('/subscriptions/cancel/$id');
      return _parseResponse(response, (d) => d as Map<String, dynamic>);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// GET /subscriptions/me
  Future<ApiResponse<List<Map<String, dynamic>>>> getMySubscriptions() async {
    try {
      final response = await _dioClient.get('/subscriptions/me');
      return _parseResponse(
        response,
        (data) => (data as List).map((x) => x as Map<String, dynamic>).toList(),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }
}
