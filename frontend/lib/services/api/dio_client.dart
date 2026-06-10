/// Dio HTTP Client with Interceptors
/// Configured for:
/// - Token attachment to requests
/// - Automatic token refresh on 401
/// - Request/response logging
/// - Error handling

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'secure_storage_simple.dart';
import 'api_constants.dart';

/// Singleton Dio HTTP client with interceptors
class DioClient {
  static final DioClient _instance = DioClient._internal();
  late final Dio _dio;
  final SecureStorage _secureStorage = SecureStorage();
  bool _isRefreshing = false;
  final List<Completer<String?>> _refreshTokenCompleters = [];

  factory DioClient() {
    return _instance;
  }

  DioClient._internal() {
    _initializeDio();
  }

  /// Initialize Dio with base configuration
  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.apiBasePath,
        connectTimeout: Duration(seconds: ApiConfig.connectionTimeoutSeconds),
        receiveTimeout: Duration(seconds: ApiConfig.receiveTimeoutSeconds),
        sendTimeout: Duration(seconds: ApiConfig.requestTimeoutSeconds),
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      ),
    );

    _dio.interceptors.add(_RequestInterceptor(this));
    _dio.interceptors.add(_ResponseInterceptor(this));

    if (ApiConfig.enableLogging) {
      _dio.interceptors.add(_LoggingInterceptor());
    }
  }

  /// Get Dio instance
  Dio get dio => _dio;

  // ─── Public token helpers (used by ApiService and interceptors) ──────────
  
  /// Set authorization header with token
  Future<void> setAuthToken(String token) async {
    _dio.options.headers[ApiHeaders.authorization] =
        '${ApiHeaders.authorizationBearer} $token';
    await _secureStorage.saveToken(token);
  }

  /// Clear authorization header
  Future<void> clearAuthToken() async {
    _dio.options.headers.remove(ApiHeaders.authorization);
    await _secureStorage.deleteToken();
  }

  /// Get current access token from secure storage
  Future<String?> getAccessToken() async {
    return await _secureStorage.getToken();
  }

  /// Get refresh token from secure storage
  Future<String?> getRefreshToken() async {
    return await _secureStorage.getRefreshToken();
  }

  /// Save both auth tokens to secure storage (public — no private field access needed)
  Future<void> saveAuthTokens(String accessToken, String refreshToken) async {
    await _secureStorage.saveAuthTokens(accessToken, refreshToken);
  }

  /// Clear all tokens (logout)
  Future<void> clearAllTokens() async {
    await _secureStorage.clearAllTokens();
    _dio.options.headers.remove(ApiHeaders.authorization);
  }

  /// Refresh access token using stored refresh token
  /// Handles concurrent refresh requests via a completer queue
  Future<String?> refreshAccessToken() async {
    if (_isRefreshing) {
      // Wait for the ongoing refresh to complete
      final completer = Completer<String?>();
      _refreshTokenCompleters.add(completer);
      return completer.future;
    }

    _isRefreshing = true;
    String? newAccessToken;

    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null) {
        debugPrint('❌ No refresh token available');
        return null;
      }

      // Use a fresh Dio instance to avoid interceptor loops
      final response = await _dio.post(
        AuthEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
        options: Options(
          headers: {
            // Do NOT send old access token here — server doesn't require it
          },
        ),
      );

      if (response.statusCode == 200) {
        // Backend returns { statusCode, status, message, data: { accessToken, refreshToken, expiresAt } }
        final responseData = response.data;
        final dataMap = (responseData is Map && responseData.containsKey('data'))
            ? responseData['data'] as Map
            : responseData as Map;

        newAccessToken = dataMap['accessToken'] as String?;
        final newRefreshToken = dataMap['refreshToken'] as String?;

        if (newAccessToken != null) {
          await setAuthToken(newAccessToken);
          // Save new refresh token if server rotated it
          if (newRefreshToken != null) {
            await _secureStorage.saveRefreshToken(newRefreshToken);
          }
          debugPrint('✅ Token refreshed successfully');
        }
      }

      return newAccessToken;
    } catch (e) {
      debugPrint('❌ Token refresh failed: $e');
      return null;
    } finally {
      _isRefreshing = false;

      // Notify all waiting requests with the result
      for (final completer in _refreshTokenCompleters) {
        if (!completer.isCompleted) {
          completer.complete(newAccessToken);
        }
      }
      _refreshTokenCompleters.clear();
    }
  }

  // ─── HTTP Methods ────────────────────────────────────────────────────────

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get(path, queryParameters: queryParameters, options: options);
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.post(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.put(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.delete(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.patch(path, data: data, queryParameters: queryParameters, options: options);
  }

  /// Upload a file using multipart/form-data
  Future<Response> uploadFile(
    String path, {
    required String fileKey,
    required String filePath,
    Map<String, dynamic>? otherData,
    ProgressCallback? onProgress,
    Options? options,
  }) async {
    final formData = FormData.fromMap({
      fileKey: await MultipartFile.fromFile(filePath),
      ...?otherData,
    });

    return _dio.post(
      path,
      data: formData,
      onSendProgress: onProgress,
      options: options,
    );
  }
}

// ============================================================================
// REQUEST INTERCEPTOR
// ============================================================================

class _RequestInterceptor extends Interceptor {
  final DioClient _dioClient;

  _RequestInterceptor(this._dioClient);

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // Attach auth token to every request
    final token = await _dioClient.getAccessToken();
    if (token != null) {
      options.headers[ApiHeaders.authorization] =
          '${ApiHeaders.authorizationBearer} $token';
    }

    return handler.next(options);
  }
}

// ============================================================================
// RESPONSE INTERCEPTOR — handles 401 → refresh → retry
// ============================================================================

class _ResponseInterceptor extends Interceptor {
  final DioClient _dioClient;

  _ResponseInterceptor(this._dioClient);

  @override
  void onResponse(
      Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 &&
        !_isTokenRefreshRequest(err.requestOptions)) {
      // Try to refresh the access token
      final newToken = await _dioClient.refreshAccessToken();

      if (newToken != null) {
        try {
          final options = err.requestOptions;
          options.headers[ApiHeaders.authorization] =
              '${ApiHeaders.authorizationBearer} $newToken';

          final response = await _dioClient.dio.request(
            options.path,
            data: options.data,
            queryParameters: options.queryParameters,
            options: Options(
              method: options.method,
              headers: options.headers,
            ),
          );

          return handler.resolve(response);
        } catch (e) {
          return handler.next(err);
        }
      }

      // Token refresh failed — clear tokens so user is redirected to login
      await _dioClient.clearAllTokens();
    }

    return handler.next(err);
  }

  bool _isTokenRefreshRequest(RequestOptions options) {
    return options.path.contains(AuthEndpoints.refreshToken);
  }
}

// ============================================================================
// LOGGING INTERCEPTOR
// ============================================================================

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (ApiConfig.enableDebugLogging) {
      debugPrint('');
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('🔵 REQUEST: ${options.method} ${options.baseUrl}${options.path}');
      debugPrint('───────────────────────────────────────────────────────────');

      if (options.queryParameters.isNotEmpty) {
        debugPrint('Query: ${options.queryParameters}');
      }

      // Log headers but mask the auth token for security
      options.headers.forEach((key, value) {
        if (key.toLowerCase() == 'authorization') {
          final masked = value.toString().length > 20
              ? '${value.toString().substring(0, 20)}...'
              : value.toString();
          debugPrint('  $key: $masked');
        } else {
          debugPrint('  $key: $value');
        }
      });

      if (options.data != null && options.data is! FormData) {
        debugPrint('Body: ${options.data}');
      }
      debugPrint('═══════════════════════════════════════════════════════════');
    }

    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (ApiConfig.enableDebugLogging) {
      debugPrint('');
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint(
          '🟢 RESPONSE: ${response.statusCode} ${response.requestOptions.path}');
      debugPrint('Body: ${response.data}');
      debugPrint('═══════════════════════════════════════════════════════════');
    }

    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('');
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('🔴 ERROR: ${err.type} - ${err.message}');
    debugPrint('Path: ${err.requestOptions.path}');
    debugPrint('Status: ${err.response?.statusCode}');
    if (err.response?.data != null) {
      debugPrint('Response: ${err.response!.data}');
    }
    debugPrint('═══════════════════════════════════════════════════════════');

    return handler.next(err);
  }
}
