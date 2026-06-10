/// File Upload Service
/// Handles file uploads with progress tracking and validation

import 'dart:io';
import 'package:flutter/foundation.dart';

/// File upload configuration
class FileUploadConfig {
  /// Maximum file size in bytes (10 MB)
  static const int maxFileSizeBytes = 10 * 1024 * 1024;

  /// Allowed image extensions
  static const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];

  /// Allowed document extensions
  static const List<String> allowedDocumentExtensions = ['pdf', 'doc', 'docx', 'txt'];

  /// Avatar width and height in pixels
  static const int avatarSize = 256;

  /// Compression quality (0-100)
  static const int compressionQuality = 85;
}

/// File validation result
class FileValidationResult {
  final bool isValid;
  final String? errorMessage;

  const FileValidationResult({
    required this.isValid,
    this.errorMessage,
  });

  /// File is valid
  FileValidationResult.valid() 
    : isValid = true,
      errorMessage = null;

  /// File is invalid
  FileValidationResult.invalid(this.errorMessage) 
    : isValid = false;
}

/// Upload progress callback
typedef UploadProgressCallback = Function(int sentBytes, int totalBytes);

/// File upload service
class FileUploadService {
  static final FileUploadService _instance = FileUploadService._internal();

  factory FileUploadService() {
    return _instance;
  }

  FileUploadService._internal();

  // ============================================================================
  // FILE VALIDATION
  // ============================================================================

  /// Validate image file
  /// 
  /// Checks:
  /// - File exists
  /// - File size <= 10 MB
  /// - File extension is allowed
  FileValidationResult validateImageFile(String filePath) {
    try {
      final file = File(filePath);

      // Check if file exists
      if (!file.existsSync()) {
        return FileValidationResult.invalid('File not found');
      }

      // Check file size
      final sizeInBytes = file.lengthSync();
      if (sizeInBytes > FileUploadConfig.maxFileSizeBytes) {
        final sizeMB = (sizeInBytes / (1024 * 1024)).toStringAsFixed(2);
        return FileValidationResult.invalid(
          'File size ($sizeMB MB) exceeds maximum (10 MB)',
        );
      }

      // Check file extension
      final extension = _getFileExtension(filePath).toLowerCase();
      if (!FileUploadConfig.allowedImageExtensions.contains(extension)) {
        return FileValidationResult.invalid(
          'File type not supported. Allowed: ${FileUploadConfig.allowedImageExtensions.join(', ')}',
        );
      }

      return FileValidationResult.valid();
    } catch (e) {
      return FileValidationResult.invalid('File validation error: $e');
    }
  }

  /// Validate document file
  FileValidationResult validateDocumentFile(String filePath) {
    try {
      final file = File(filePath);

      // Check if file exists
      if (!file.existsSync()) {
        return FileValidationResult.invalid('File not found');
      }

      // Check file size
      final sizeInBytes = file.lengthSync();
      if (sizeInBytes > FileUploadConfig.maxFileSizeBytes) {
        final sizeMB = (sizeInBytes / (1024 * 1024)).toStringAsFixed(2);
        return FileValidationResult.invalid(
          'File size ($sizeMB MB) exceeds maximum (10 MB)',
        );
      }

      // Check file extension
      final extension = _getFileExtension(filePath).toLowerCase();
      if (!FileUploadConfig.allowedDocumentExtensions.contains(extension)) {
        return FileValidationResult.invalid(
          'File type not supported. Allowed: ${FileUploadConfig.allowedDocumentExtensions.join(', ')}',
        );
      }

      return FileValidationResult.valid();
    } catch (e) {
      return FileValidationResult.invalid('File validation error: $e');
    }
  }

  // ============================================================================
  // FILE UTILITIES
  // ============================================================================

  /// Get file extension without the dot
  String _getFileExtension(String filePath) {
    final lastDotIndex = filePath.lastIndexOf('.');
    if (lastDotIndex == -1) return '';
    return filePath.substring(lastDotIndex + 1);
  }

  /// Get file name from path
  String getFileName(String filePath) {
    return filePath.split('/').last;
  }

  /// Get file size in MB
  double getFileSizeInMB(String filePath) {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return 0.0;
      return file.lengthSync() / (1024 * 1024);
    } catch (e) {
      return 0.0;
    }
  }

  /// Get file size in bytes
  int getFileSizeInBytes(String filePath) {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return 0;
      return file.lengthSync();
    } catch (e) {
      return 0;
    }
  }

  /// Get formatted file size
  String getFormattedFileSize(int sizeInBytes) {
    if (sizeInBytes < 1024) {
      return '$sizeInBytes B';
    } else if (sizeInBytes < 1024 * 1024) {
      final kb = (sizeInBytes / 1024).toStringAsFixed(2);
      return '$kb KB';
    } else {
      final mb = (sizeInBytes / (1024 * 1024)).toStringAsFixed(2);
      return '$mb MB';
    }
  }

  /// Get progress percentage
  int getProgressPercentage(int sentBytes, int totalBytes) {
    if (totalBytes == 0) return 0;
    return ((sentBytes / totalBytes) * 100).toInt();
  }

  // ============================================================================
  // UPLOAD SIMULATION (for testing)
  // ============================================================================

  /// Simulate file upload with progress
  /// 
  /// For testing purposes - calls onProgress repeatedly
  /// Completes successfully after delay
  Future<void> simulateUpload({
    required String filePath,
    required UploadProgressCallback onProgress,
    Duration duration = const Duration(seconds: 3),
  }) async {
    final totalSize = getFileSizeInBytes(filePath);
    final stepCount = 20; // Simulate 20 progress updates
    final stepDuration = duration ~/ stepCount;

    debugPrint('📤 Simulating upload for: ${getFileName(filePath)}');

    for (int i = 1; i <= stepCount; i++) {
      await Future.delayed(stepDuration);
      final sentBytes = (totalSize * i / stepCount).toInt();
      onProgress(sentBytes, totalSize);
      debugPrint('📊 Upload progress: ${getProgressPercentage(sentBytes, totalSize)}%');
    }

    debugPrint('✅ Upload complete');
  }

  // ============================================================================
  // FILE INFO
  // ============================================================================

  /// Get detailed file information
  Map<String, dynamic> getFileInfo(String filePath) {
    try {
      final file = File(filePath);
      final fileName = getFileName(filePath);
      final sizeInBytes = file.lengthSync();
      final extension = _getFileExtension(filePath);

      return {
        'path': filePath,
        'name': fileName,
        'extension': extension,
        'sizeInBytes': sizeInBytes,
        'sizeInMB': (sizeInBytes / (1024 * 1024)).toStringAsFixed(2),
        'formattedSize': getFormattedFileSize(sizeInBytes),
        'lastModified': file.lastModifiedSync().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': 'Failed to get file info: $e',
      };
    }
  }

  /// Print file information
  void printFileInfo(String filePath) {
    final info = getFileInfo(filePath);
    debugPrint('''
╔════════════════════════════════════════════════════════════════╗
║                       FILE INFORMATION                         ║
╠════════════════════════════════════════════════════════════════╣
║ Name: ${info['name']}
║ Size: ${info['formattedSize']}
║ Extension: ${info['extension']}
║ Last Modified: ${info['lastModified']}
╚════════════════════════════════════════════════════════════════╝
    ''');
  }
}
