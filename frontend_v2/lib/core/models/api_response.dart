import 'package:equatable/equatable.dart';

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

  bool get isSuccess => success && data != null;
  bool get hasError => !success && error != null;
  String? get errorMessage => message ?? error;

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

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    final success = json['success'] as bool? ?? false;
    final statusCode = json['statusCode'] as int?;
    final message = json['message'] as String?;
    final error = json['error'] as String?;

    if (success && json['data'] != null) {
      return ApiResponse(
        success: true,
        data: fromJsonT(json['data']),
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

  @override
  List<Object?> get props => [success, data, message, error, statusCode];
}

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

  @override
  List<Object?> get props => [success, message];
}

class StringResponse extends Equatable {
  final String value;

  const StringResponse(this.value);

  factory StringResponse.fromJson(dynamic json) {
    if (json is String) {
      return StringResponse(json);
    }
    return StringResponse(json.toString());
  }

  @override
  List<Object?> get props => [value];
}
