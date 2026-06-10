/// API Response Models
/// Wraps backend API responses in type-safe Dart models

import 'package:equatable/equatable.dart';

// ============================================================================
// GENERIC API RESPONSE WRAPPER
// ============================================================================

/// Generic API response wrapper for all endpoints
/// Backend returns: { success, data?, error? }
class ApiResponse<T> extends Equatable {
  final bool success;
  final T? data;
  final String? message;
  final String? error;
  final int? statusCode;

  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
    this.statusCode,
  });

  /// Check if response is successful
  bool get isSuccess => success && data != null;

  /// Check if response has error
  bool get hasError => !success && error != null;

  /// Get error message (prefer message field, fallback to error)
  String? get errorMessage => message ?? error;

  /// Factory constructor for successful response
  factory ApiResponse.success({
    required T data,
    String? message,
    int? statusCode,
  }) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
      statusCode: statusCode,
    );
  }

  /// Factory constructor for error response
  factory ApiResponse.error({
    required String error,
    String? message,
    int? statusCode,
  }) {
    return ApiResponse(
      success: false,
      data: null,
      error: error,
      message: message,
      statusCode: statusCode ?? 500,
    );
  }

  /// Factory constructor from JSON
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJson,
  ) {
    final success = json['success'] as bool? ?? false;
    final statusCode = json['statusCode'] as int?;
    final message = json['message'] as String?;
    final error = json['error'] as String?;

    if (success && json['data'] != null) {
      return ApiResponse(
        success: true,
        data: fromJson(json['data']),
        message: message,
        statusCode: statusCode,
      );
    } else {
      return ApiResponse(
        success: false,
        error: error ?? 'Unknown error',
        message: message,
        statusCode: statusCode ?? 500,
      );
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson(Object? Function(T)? toJsonT) {
    return {
      'success': success,
      'data': data != null && toJsonT != null ? toJsonT(data!) : null,
      'message': message,
      'error': error,
      'statusCode': statusCode,
    };
  }

  @override
  List<Object?> get props => [success, data, message, error, statusCode];
}

// ============================================================================
// ERROR RESPONSE
// ============================================================================

/// Represents an API error response
class ErrorResponse extends Equatable {
  final bool success;
  final String error;
  final String? message;
  final Map<String, dynamic>? details;
  final int statusCode;

  const ErrorResponse({
    required this.error,
    required this.statusCode,
    this.message,
    this.details,
  }) : success = false;

  /// Factory constructor from JSON
  factory ErrorResponse.fromJson(Map<String, dynamic> json) {
    return ErrorResponse(
      error: json['error'] as String? ?? 'Unknown error',
      message: json['message'] as String?,
      details: json['details'] as Map<String, dynamic>?,
      statusCode: json['statusCode'] as int? ?? 500,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'error': error,
      'message': message,
      'details': details,
      'statusCode': statusCode,
    };
  }

  /// Get user-friendly error message
  String get userMessage {
    if (message != null) {
      return message!;
    }

    // Map error codes to user-friendly messages
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Session expired. Please login again.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'The requested resource was not found.';
      case 409:
        return 'This resource already exists.';
      case 429:
        return 'Too many requests. Please wait before trying again.';
      case 500:
      case 502:
      case 503:
        return 'Server error. Please try again later.';
      default:
        return error;
    }
  }

  @override
  List<Object?> get props => [error, message, details, statusCode];
}

// ============================================================================
// VALIDATION ERROR RESPONSE
// ============================================================================

/// Represents validation errors from the backend
class ValidationErrorResponse extends ErrorResponse {
  final Map<String, List<String>>? fieldErrors;

  ValidationErrorResponse({
    required String error,
    required int statusCode,
    String? message,
    this.fieldErrors,
  }) : super(
    error: error,
    statusCode: statusCode,
    message: message,
  );

  /// Factory constructor from JSON
  factory ValidationErrorResponse.fromJson(Map<String, dynamic> json) {
    return ValidationErrorResponse(
      error: json['error'] as String? ?? 'Validation error',
      message: json['message'] as String?,
      statusCode: json['statusCode'] as int? ?? 422,
      fieldErrors: _parseFieldErrors(json['errors'] as Map<String, dynamic>?),
    );
  }

  /// Get error message for a specific field
  List<String>? getFieldErrors(String fieldName) {
    return fieldErrors?[fieldName];
  }

  /// Check if specific field has errors
  bool hasFieldError(String fieldName) {
    return fieldErrors?.containsKey(fieldName) ?? false;
  }

  /// Parse field errors from response
  static Map<String, List<String>>? _parseFieldErrors(
    Map<String, dynamic>? errors,
  ) {
    if (errors == null) return null;

    final result = <String, List<String>>{};
    errors.forEach((key, value) {
      if (value is List) {
        result[key] = value.map((e) => e.toString()).toList();
      } else if (value is String) {
        result[key] = [value];
      }
    });

    return result.isEmpty ? null : result;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'errors': fieldErrors,
    };
  }

  @override
  List<Object?> get props => [error, message, fieldErrors, statusCode];
}

// ============================================================================
// PAGINATION RESPONSE
// ============================================================================

/// Represents a paginated API response
class PaginatedResponse<T> extends Equatable {
  final List<T> data;
  final int total;
  final int limit;
  final int offset;
  final bool hasMore;

  const PaginatedResponse({
    required this.data,
    required this.total,
    required this.limit,
    required this.offset,
    required this.hasMore,
  });

  /// Get current page number (offset-based)
  int get page => (offset / limit).floor() + 1;

  /// Get total pages
  int get totalPages => (total / limit).ceil();

  /// Factory constructor from JSON
  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJson,
  ) {
    final dataList = (json['data'] as List<dynamic>?)
        ?.map((item) => fromJson(item))
        .toList() ?? [];
    final total = json['total'] as int? ?? dataList.length;
    final limit = json['limit'] as int? ?? 20;
    final offset = json['offset'] as int? ?? 0;
    final hasMore = json['hasMore'] as bool? ?? (offset + limit < total);

    return PaginatedResponse(
      data: dataList,
      total: total,
      limit: limit,
      offset: offset,
      hasMore: hasMore,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson(Object? Function(T)? toJsonT) {
    return {
      'data': toJsonT != null ? data.map(toJsonT).toList() : data,
      'total': total,
      'limit': limit,
      'offset': offset,
      'hasMore': hasMore,
    };
  }

  @override
  List<Object?> get props => [data, total, limit, offset, hasMore];
}

// ============================================================================
// COMMON RESPONSE MODELS
// ============================================================================

/// Success response with no data
class EmptyResponse extends Equatable {
  final bool success;
  final String? message;

  const EmptyResponse({
    required this.success,
    this.message,
  });

  factory EmptyResponse.fromJson(Map<String, dynamic> json) {
    return EmptyResponse(
      success: json['success'] as bool? ?? true,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
    };
  }

  @override
  List<Object?> get props => [success, message];
}

/// Generic string response
class StringResponse extends Equatable {
  final String value;

  const StringResponse(this.value);

  factory StringResponse.fromJson(dynamic json) {
    if (json is String) {
      return StringResponse(json);
    }
    return StringResponse(json.toString());
  }

  String toJson() => value;

  @override
  List<Object?> get props => [value];
}

/// Token response
class TokenResponse extends Equatable {
  final String token;
  final String? type;
  final int? expiresIn;

  const TokenResponse({
    required this.token,
    this.type = 'Bearer',
    this.expiresIn,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      token: json['token'] as String? ?? '',
      type: json['type'] as String? ?? 'Bearer',
      expiresIn: json['expiresIn'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'type': type,
      'expiresIn': expiresIn,
    };
  }

  @override
  List<Object?> get props => [token, type, expiresIn];
}
