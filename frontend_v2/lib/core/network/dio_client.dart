import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'secure_storage_service.dart';
import 'api_constants.dart';

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

  Dio get dio => _dio;

  Future<void> setAuthToken(String token) async {
    _dio.options.headers[ApiHeaders.authorization] =
        '${ApiHeaders.authorizationBearer} $token';
    await _secureStorage.saveToken(token);
  }

  Future<void> clearAuthToken() async {
    _dio.options.headers.remove(ApiHeaders.authorization);
    await _secureStorage.deleteToken();
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.getToken();
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.getRefreshToken();
  }

  Future<void> saveAuthTokens(String accessToken, String refreshToken) async {
    await _secureStorage.saveAuthTokens(accessToken, refreshToken);
  }

  Future<void> clearAllTokens() async {
    await _secureStorage.clearAllTokens();
    _dio.options.headers.remove(ApiHeaders.authorization);
  }

  Future<String?> refreshAccessToken() async {
    if (_isRefreshing) {
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

      // Create a fresh Dio instance to avoid interceptor loops
      final freshDio = Dio(BaseOptions(baseUrl: ApiConfig.apiBasePath));
      final response = await freshDio.post(
        AuthEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        final dataMap = (responseData is Map && responseData.containsKey('data'))
            ? responseData['data'] as Map
            : responseData as Map;

        newAccessToken = dataMap['accessToken'] as String?;
        final newRefreshToken = dataMap['refreshToken'] as String?;

        if (newAccessToken != null) {
          await setAuthToken(newAccessToken);
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
      for (final completer in _refreshTokenCompleters) {
        if (!completer.isCompleted) {
          completer.complete(newAccessToken);
        }
      }
      _refreshTokenCompleters.clear();
    }
  }

  // HTTP Method wrappers
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
}

class _RequestInterceptor extends Interceptor {
  final DioClient _dioClient;

  _RequestInterceptor(this._dioClient);

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _dioClient.getAccessToken();
    if (token != null) {
      options.headers[ApiHeaders.authorization] =
          '${ApiHeaders.authorizationBearer} $token';
    }
    return handler.next(options);
  }
}

class _ResponseInterceptor extends Interceptor {
  final DioClient _dioClient;

  _ResponseInterceptor(this._dioClient);

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 &&
        !err.requestOptions.path.contains(AuthEndpoints.refreshToken)) {
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
        } catch (_) {
          return handler.next(err);
        }
      }
      await _dioClient.clearAllTokens();
    }
    return handler.next(err);
  }
}

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (ApiConfig.enableDebugLogging) {
      debugPrint('🔵 REQUEST: ${options.method} ${options.baseUrl}${options.path}');
      if (options.queryParameters.isNotEmpty) {
        debugPrint('   Query: ${options.queryParameters}');
      }
      if (options.data != null) {
        debugPrint('   Body: ${options.data}');
      }
    }
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (ApiConfig.enableDebugLogging) {
      debugPrint('🟢 RESPONSE: ${response.statusCode} ${response.requestOptions.path}');
      debugPrint('   Body: ${response.data}');
    }
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('🔴 ERROR: ${err.type} - ${err.message}');
    debugPrint('   Path: ${err.requestOptions.path}');
    debugPrint('   Status: ${err.response?.statusCode}');
    if (err.response?.data != null) {
      debugPrint('   Response: ${err.response!.data}');
    }
    return handler.next(err);
  }
}
