/// Error Handling Utility
/// Centralized error handling and user-friendly messages

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/api/api_response.dart';
import '../services/auth/auth_service.dart';

/// Application error types
enum ErrorType {
  network,       // Network connectivity error
  timeout,       // Request timeout
  validation,    // Form/input validation error
  authentication, // Auth-related error
  authorization, // Permission error
  notFound,      // Resource not found
  conflict,      // Conflict (e.g., duplicate)
  serverError,   // 5xx server error
  unknown,       // Unknown error
}

/// Application error wrapper
class AppError {
  final String message;
  final ErrorType type;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppError({
    required this.message,
    required this.type,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  /// Network error
  AppError.network({
    String? message,
    dynamic originalError,
  })  : message = message ?? 'Network connection failed. Please check your internet connection.',
        type = ErrorType.network,
        code = 'NETWORK_ERROR',
        originalError = originalError,
        stackTrace = null;

  /// Timeout error
  AppError.timeout({
    String? message,
    dynamic originalError,
  })  : message = message ?? 'Request timed out. Please try again.',
        type = ErrorType.timeout,
        code = 'TIMEOUT_ERROR',
        originalError = originalError,
        stackTrace = null;

  /// Validation error
  AppError.validation({
    required this.message,
  })  : type = ErrorType.validation,
        code = 'VALIDATION_ERROR',
        originalError = null,
        stackTrace = null;

  /// Authentication error
  AppError.authentication({
    String? message,
    dynamic originalError,
  })  : message = message ?? 'Authentication failed. Please login again.',
        type = ErrorType.authentication,
        code = 'AUTH_ERROR',
        originalError = originalError,
        stackTrace = null;

  /// Authorization error
  AppError.authorization({
    String? message,
    dynamic originalError,
  })  : message = message ?? 'You do not have permission to perform this action.',
        type = ErrorType.authorization,
        code = 'AUTHZ_ERROR',
        originalError = originalError,
        stackTrace = null;

  /// Server error
  AppError.serverError({
    String? message,
    dynamic originalError,
  })  : message = message ?? 'Server error occurred. Please try again later.',
        type = ErrorType.serverError,
        code = 'SERVER_ERROR',
        originalError = originalError,
        stackTrace = null;

  /// Unknown error
  AppError.unknown({
    required this.message,
    dynamic originalError,
    StackTrace? stackTrace,
  })  : type = ErrorType.unknown,
        code = 'UNKNOWN_ERROR',
        originalError = originalError,
        stackTrace = stackTrace;

  @override
  String toString() => 'AppError: $message (type: $type, code: $code)';
}

/// Error handler utility
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();

  factory ErrorHandler() {
    return _instance;
  }

  ErrorHandler._internal();

  // ============================================================================
  // ERROR CONVERSION
  // ============================================================================

  /// Convert various error types to AppError
  AppError handleError(dynamic error, [StackTrace? stackTrace]) {
    debugPrint('❌ Error caught: $error');

    // Handle AuthException
    if (error is AuthException) {
      return AppError.authentication(
        message: error.message,
        originalError: error,
      );
    }

    // Handle DioException
    if (error is DioException) {
      return _handleDioException(error, stackTrace);
    }

    // Handle ApiResponse error
    if (error is ApiResponse) {
      return _handleApiResponseError(error);
    }

    // Handle String error message
    if (error is String) {
      return AppError.unknown(
        message: error,
        stackTrace: stackTrace,
      );
    }

    // Handle Exception
    if (error is Exception) {
      return AppError.unknown(
        message: error.toString(),
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Default unknown error
    return AppError.unknown(
      message: 'An unexpected error occurred. Please try again.',
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Handle DioException with status codes
  AppError _handleDioException(DioException exception, StackTrace? stackTrace) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return AppError.timeout(
          message: 'Request timed out. Please try again.',
          originalError: exception,
        );

      case DioExceptionType.connectionError:
        return AppError.network(
          message: 'No internet connection. Please check your network.',
          originalError: exception,
        );

      case DioExceptionType.cancel:
        return AppError.unknown(
          message: 'Request cancelled.',
          originalError: exception,
          stackTrace: stackTrace,
        );

      case DioExceptionType.badResponse:
        return _handleBadResponse(exception.response, exception);

      default:
        return AppError.network(
          message: 'Network error occurred. Please try again.',
          originalError: exception,
        );
    }
  }

  /// Handle bad HTTP response
  AppError _handleBadResponse(Response? response, DioException exception) {
    final statusCode = response?.statusCode ?? 0;

    switch (statusCode) {
      case 400:
        return AppError.validation(
          message: _extractErrorMessage(response) ?? 'Invalid request.',
        );

      case 401:
        return AppError.authentication(
          message: 'Your session has expired. Please login again.',
          originalError: exception,
        );

      case 403:
        return AppError.authorization(
          message: 'You do not have permission to access this resource.',
          originalError: exception,
        );

      case 404:
        return AppError(
          message: 'Resource not found.',
          type: ErrorType.notFound,
          code: 'NOT_FOUND',
          originalError: exception,
        );

      case 409:
        return AppError(
          message: _extractErrorMessage(response) ?? 'Conflict with existing data.',
          type: ErrorType.conflict,
          code: 'CONFLICT',
          originalError: exception,
        );

      case 500:
      case 502:
      case 503:
        return AppError.serverError(
          message: 'Server error occurred. Please try again later.',
          originalError: exception,
        );

      default:
        return AppError.unknown(
          message: 'HTTP Error $statusCode: ${_extractErrorMessage(response) ?? 'Unknown error'}',
          originalError: exception,
        );
    }
  }

  /// Handle ApiResponse error
  AppError _handleApiResponseError(ApiResponse error) {
    return AppError.unknown(
      message: error.errorMessage ?? 'An error occurred. Please try again.',
      originalError: error,
    );
  }

  // ============================================================================
  // ERROR MESSAGE EXTRACTION
  // ============================================================================

  /// Extract error message from HTTP response
  String? _extractErrorMessage(Response? response) {
    if (response == null) return null;

    try {
      final data = response.data;

      if (data is Map<String, dynamic>) {
        // Try common error message fields
        return data['message'] ??
            data['error'] ??
            data['errorMessage'] ??
            data['msg'] ??
            null;
      }

      if (data is String) {
        return data;
      }
    } catch (e) {
      debugPrint('Error extracting message: $e');
    }

    return null;
  }

  // ============================================================================
  // USER-FRIENDLY MESSAGES
  // ============================================================================

  /// Get user-friendly error message for UI display
  String getUserMessage(AppError error) {
    return error.message;
  }

  /// Get error icon based on type
  String getErrorIcon(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return '📡'; // Network
      case ErrorType.timeout:
        return '⏱️'; // Timeout
      case ErrorType.validation:
        return '⚠️'; // Validation
      case ErrorType.authentication:
        return '🔐'; // Auth
      case ErrorType.authorization:
        return '🚫'; // Permission
      case ErrorType.notFound:
        return '🔍'; // Not found
      case ErrorType.conflict:
        return '⚡'; // Conflict
      case ErrorType.serverError:
        return '🖥️'; // Server
      case ErrorType.unknown:
        return '❌'; // Unknown
    }
  }

  /// Get error color for UI (red, orange, etc.)
  int getErrorColor(ErrorType type) {
    switch (type) {
      case ErrorType.validation:
        return 0xFFFF9800; // Orange
      case ErrorType.authentication:
      case ErrorType.authorization:
        return 0xFFFF5722; // Deep orange
      case ErrorType.network:
      case ErrorType.timeout:
        return 0xFF2196F3; // Blue
      default:
        return 0xFFF44336; // Red
    }
  }

  // ============================================================================
  // LOGGING
  // ============================================================================

  /// Log error with full details
  void logError(AppError error) {
    debugPrint('''
╔════════════════════════════════════════════════════════════════╗
║                        ERROR DETAILS                           ║
╠════════════════════════════════════════════════════════════════╣
║ Type: ${error.type}
║ Code: ${error.code}
║ Message: ${error.message}
║ Original Error: ${error.originalError}
╚════════════════════════════════════════════════════════════════╝
    ''');

    if (error.stackTrace != null) {
      debugPrint('Stack Trace: ${error.stackTrace}');
    }
  }

  /// Log error to analytics/tracking service
  void reportError(AppError error) {
    // TODO: Implement error reporting to analytics service
    debugPrint('📊 Reporting error to analytics: ${error.code}');
  }
}
