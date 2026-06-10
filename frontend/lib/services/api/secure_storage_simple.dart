/// Simplified Secure Storage Wrapper
/// Used by DioClient for token management

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'api_constants.dart';

/// Simplified secure storage for tokens
class SecureStorage {
  static final SecureStorage _instance = SecureStorage._internal();
  late final FlutterSecureStorage _storage;

  factory SecureStorage() {
    return _instance;
  }

  SecureStorage._internal() {
    _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
        storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
        resetOnError: true,
      ),
    );
  }

  /// Save access token
  Future<void> saveToken(String token) async {
    try {
      await _storage.write(
        key: TokenConfig.accessTokenKey,
        value: token,
      );
    } catch (e) {
      throw Exception('Failed to save token: $e');
    }
  }

  /// Get access token
  Future<String?> getToken() async {
    try {
      return await _storage.read(key: TokenConfig.accessTokenKey);
    } catch (e) {
      return null;
    }
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    try {
      await _storage.write(
        key: TokenConfig.refreshTokenKey,
        value: token,
      );
    } catch (e) {
      throw Exception('Failed to save refresh token: $e');
    }
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: TokenConfig.refreshTokenKey);
    } catch (e) {
      return null;
    }
  }

  /// Delete access token
  Future<void> deleteToken() async {
    try {
      await _storage.delete(key: TokenConfig.accessTokenKey);
    } catch (e) {
      // Ignore errors on deletion
    }
  }

  /// Delete refresh token
  Future<void> deleteRefreshToken() async {
    try {
      await _storage.delete(key: TokenConfig.refreshTokenKey);
    } catch (e) {
      // Ignore errors on deletion
    }
  }

  /// Clear all tokens (logout)
  Future<void> clearAllTokens() async {
    try {
      await Future.wait([
        _storage.delete(key: TokenConfig.accessTokenKey),
        _storage.delete(key: TokenConfig.refreshTokenKey),
      ]);
    } catch (e) {
      // Ignore errors on deletion
    }
  }

  /// Check if user is authenticated (has valid token)
  Future<bool> isAuthenticated() async {
    try {
      final token = await getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Save both tokens at once
  Future<void> saveAuthTokens(String accessToken, String refreshToken) async {
    try {
      await Future.wait([
        saveToken(accessToken),
        saveRefreshToken(refreshToken),
      ]);
    } catch (e) {
      throw Exception('Failed to save auth tokens: $e');
    }
  }
}
