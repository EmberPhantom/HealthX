/// API Exception and Error Handling
import 'package:dio/dio.dart';

// ════════════════════════════════════════════════════════════════════
// Base API Exception
// ════════════════════════════════════════════════════════════════════

abstract class ApiException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  ApiException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'ApiException: $message${code != null ? ' (Code: $code)' : ''}';
}

// ════════════════════════════════════════════════════════════════════
// Specific Exception Types
// ════════════════════════════════════════════════════════════════════

class AuthException extends ApiException {
  AuthException({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(
    message: message,
    code: code,
    originalError: originalError,
  );

  factory AuthException.from(DioException error) {
    final data = error.response?.data;
    final message = data is Map ? data['message'] ?? data['error'] : null;
    
    return AuthException(
      message: message ?? 'Authentication failed',
      code: error.response?.statusCode.toString(),
      originalError: error,
    );
  }

  @override
  String toString() => 'AuthException: $message';
}

class ValidationException extends ApiException {
  final Map<String, dynamic>? errors;

  ValidationException({
    required String message,
    String? code,
    this.errors,
    dynamic originalError,
  }) : super(
    message: message,
    code: code,
    originalError: originalError,
  );

  factory ValidationException.from(DioException error) {
    final data = error.response?.data;
    final message = data is Map ? data['message'] ?? 'Validation failed' : 'Validation failed';
    final errors = data is Map ? data['errors'] : null;

    return ValidationException(
      message: message,
      code: error.response?.statusCode.toString(),
      errors: errors is Map ? Map<String, dynamic>.from(errors) : null,
      originalError: error,
    );
  }

  @override
  String toString() => 'ValidationException: $message${errors != null ? ' - $errors' : ''}';
}

class ServerException extends ApiException {
  ServerException({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(
    message: message,
    code: code,
    originalError: originalError,
  );

  factory ServerException.from(DioException error) {
    final data = error.response?.data;
    final message = data is Map ? data['message'] ?? 'Server error' : 'Server error';

    return ServerException(
      message: message,
      code: error.response?.statusCode.toString(),
      originalError: error,
    );
  }

  @override
  String toString() => 'ServerException: $message';
}

class NetworkException extends ApiException {
  NetworkException({
    required String message,
    dynamic originalError,
  }) : super(
    message: message,
    originalError: originalError,
  );

  factory NetworkException.from(DioException error) {
    return NetworkException(
      message: _networkErrorMessage(error),
      originalError: error,
    );
  }

  static String _networkErrorMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout - please check your internet connection';
      case DioExceptionType.sendTimeout:
        return 'Request timeout - please try again';
      case DioExceptionType.receiveTimeout:
        return 'Response timeout - please try again';
      case DioExceptionType.connectionError:
        return 'Network error - please check your internet connection';
      default:
        return 'Network error occurred';
    }
  }

  @override
  String toString() => 'NetworkException: $message';
}

class TokenException extends ApiException {
  TokenException({
    required String message,
    dynamic originalError,
  }) : super(
    message: message,
    originalError: originalError,
  );

  @override
  String toString() => 'TokenException: $message';
}

// ════════════════════════════════════════════════════════════════════
// Exception Factory
// ════════════════════════════════════════════════════════════════════

class ApiExceptionFactory {
  static ApiException create(dynamic error) {
    if (error is DioException) {
      return _createFromDioException(error);
    }
    
    if (error is ApiException) {
      return error;
    }

    return ServerException(
      message: error.toString(),
      originalError: error,
    );
  }

  static ApiException _createFromDioException(DioException error) {
    final statusCode = error.response?.statusCode ?? 0;
    final data = error.response?.data;

    // Network errors
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return NetworkException.from(error);
    }

    // HTTP status codes
    switch (statusCode) {
      case 400:
        return ValidationException.from(error);
      case 401:
      case 403:
        return AuthException.from(error);
      case 404:
        return ServerException(
          message: 'Resource not found',
          code: '404',
          originalError: error,
        );
      case 429:
        return ServerException(
          message: 'Too many requests - please try again later',
          code: '429',
          originalError: error,
        );
      case 500:
      case 502:
      case 503:
      case 504:
        return ServerException.from(error);
      default:
        return ServerException(
          message: data is Map ? data['message'] ?? 'Unknown error' : 'Unknown error',
          code: statusCode.toString(),
          originalError: error,
        );
    }
  }

  static String getUserFriendlyMessage(ApiException exception) {
    if (exception is NetworkException) {
      return exception.message;
    }

    if (exception is ValidationException) {
      if (exception.errors != null) {
        final firstError = exception.errors?.values.first;
        return firstError?.toString() ?? exception.message;
      }
      return 'Please check your input and try again';
    }

    if (exception is AuthException) {
      return 'Authentication failed - please try logging in again';
    }

    if (exception is ServerException) {
      return 'Server error - please try again soon';
    }

    return exception.message;
  }
}
