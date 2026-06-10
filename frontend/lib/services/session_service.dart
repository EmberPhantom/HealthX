/// Session Service
/// Manages user session lifecycle:
/// - Session initialization on app startup
/// - Token refresh scheduling
/// - Session expiry handling
/// - Auto-logout on token expiry

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/api/auth_models.dart';
import 'auth/auth_service.dart';
import 'api/api_constants.dart';

/// Session state
enum SessionStatus {
  uninitialized, // Session not yet initialized
  authenticated, // User is authenticated with valid token
  tokenExpiring, // Access token expiring soon
  expired, // Session has expired
  unauthenticated, // User is not authenticated
}

/// Session service managing user session
class SessionService {
  static final SessionService _instance = SessionService._internal();

  final AuthService _authService = AuthService();

  SessionStatus _status = SessionStatus.uninitialized;
  DateTime? _tokenExpiryTime;
  Timer? _refreshTimer;
  Timer? _expiryTimer;

  // Callbacks for state changes
  final List<Function(SessionStatus)> _statusCallbacks = [];
  final List<Function()> _expiryCallbacks = [];

  factory SessionService() {
    return _instance;
  }

  SessionService._internal();

  // ============================================================================
  // PROPERTIES
  // ============================================================================

  /// Get current session status
  SessionStatus get status => _status;

  /// Check if session is active
  bool get isActive =>
      _status == SessionStatus.authenticated ||
      _status == SessionStatus.tokenExpiring;

  /// Check if authenticated
  bool get isAuthenticated => _status == SessionStatus.authenticated;

  /// Get token expiry time
  DateTime? get tokenExpiryTime => _tokenExpiryTime;

  /// Get time until token expires
  Duration? get timeUntilExpiry {
    if (_tokenExpiryTime == null) return null;
    final now = DateTime.now();
    if (now.isAfter(_tokenExpiryTime!)) {
      return Duration.zero;
    }
    return _tokenExpiryTime!.difference(now);
  }

  // ============================================================================
  // SESSION INITIALIZATION
  // ============================================================================

  /// Initialize session on app startup
  Future<bool> initializeSession() async {
    debugPrint('🔄 Initializing session');
    _setStatus(SessionStatus.uninitialized);

    try {
      final token = await _authService.accessToken;

      if (token == null) {
        debugPrint('❌ No saved token found');
        _setStatus(SessionStatus.unauthenticated);
        return false;
      }

      // Session is valid (token was restored)
      _setStatus(SessionStatus.authenticated);
      
      // Schedule token refresh
      _scheduleTokenRefresh();

      debugPrint('✅ Session initialized and active');
      return true;
    } catch (e) {
      debugPrint('❌ Session initialization failed: $e');
      _setStatus(SessionStatus.unauthenticated);
      return false;
    }
  }

  /// Restore session after user login
  Future<void> onUserLoggedIn({
    required UserProfile user,
    required int accessTokenExpirySeconds,
  }) async {
    debugPrint('👤 User logged in: ${user.email}');

    // Calculate token expiry time
    _tokenExpiryTime = DateTime.now().add(
      Duration(seconds: accessTokenExpirySeconds),
    );

    _setStatus(SessionStatus.authenticated);

    // Schedule token refresh before expiry
    _scheduleTokenRefresh();
  }

  /// Handle user logout
  Future<void> onUserLoggedOut() async {
    debugPrint('🚪 User logged out');

    // Cancel timers
    _refreshTimer?.cancel();
    _expiryTimer?.cancel();

    _tokenExpiryTime = null;
    _setStatus(SessionStatus.unauthenticated);
  }

  // ============================================================================
  // TOKEN REFRESH LOGIC
  // ============================================================================

  /// Schedule automatic token refresh
  void _scheduleTokenRefresh() {
    // Cancel existing timers
    _refreshTimer?.cancel();
    _expiryTimer?.cancel();

    if (_tokenExpiryTime == null) {
      debugPrint('⚠️ Token expiry time not set');
      return;
    }

    final now = DateTime.now();
    final expiryTime = _tokenExpiryTime!;
    final totalDuration = expiryTime.difference(now);

    // Refresh token 5 minutes before expiry
    final refreshThreshold = Duration(
      minutes: TokenConfig.refreshTokenThresholdMinutes,
    );

    if (totalDuration <= refreshThreshold) {
      // Token expires soon, refresh immediately
      debugPrint('⚡ Token expires very soon, refreshing immediately');
      _refreshTokenNow();
    } else {
      // Schedule refresh for threshold time
      final refreshDuration = totalDuration - refreshThreshold;

      debugPrint('📅 Scheduled token refresh in ${refreshDuration.inMinutes} minutes');

      _refreshTimer = Timer(refreshDuration, () {
        debugPrint('⏰ Token refresh timer triggered');
        _refreshTokenNow();
      });
    }

    // Schedule expiry notification (for UI updates)
    _expiryTimer = Timer(totalDuration, () {
      debugPrint('⚠️ Token has expired');
      _setStatus(SessionStatus.expired);
      _notifyExpiryCallbacks();
    });
  }

  /// Refresh token immediately
  Future<void> _refreshTokenNow() async {
    try {
      debugPrint('🔄 Refreshing access token');

      final newToken = await _authService.refreshAccessToken();

      // Update token expiry time
      _tokenExpiryTime = DateTime.now().add(
        Duration(minutes: TokenConfig.accessTokenExpiryMinutes),
      );

      _setStatus(SessionStatus.authenticated);

      // Reschedule next refresh
      _scheduleTokenRefresh();

      debugPrint('✅ Token refreshed successfully');
    } catch (e) {
      debugPrint('❌ Token refresh failed: $e');

      // Session expired, logout user
      _setStatus(SessionStatus.expired);
      _notifyExpiryCallbacks();
    }
  }

  /// Force token refresh (manual)
  Future<bool> manualRefreshToken() async {
    try {
      debugPrint('🔄 Manual token refresh requested');

      await _refreshTokenNow();
      return true;
    } catch (e) {
      debugPrint('❌ Manual refresh failed: $e');
      return false;
    }
  }

  // ============================================================================
  // SESSION STATUS CALLBACKS
  // ============================================================================

  /// Subscribe to session status changes
  void onStatusChanged(Function(SessionStatus) callback) {
    _statusCallbacks.add(callback);
  }

  /// Unsubscribe from session status changes
  void offStatusChanged(Function(SessionStatus) callback) {
    _statusCallbacks.remove(callback);
  }

  /// Subscribe to session expiry events
  void onSessionExpiry(Function() callback) {
    _expiryCallbacks.add(callback);
  }

  /// Unsubscribe from session expiry events
  void offSessionExpiry(Function() callback) {
    _expiryCallbacks.remove(callback);
  }

  /// Notify status change listeners
  void _setStatus(SessionStatus newStatus) {
    if (_status == newStatus) return;

    _status = newStatus;
    debugPrint('📊 Session status changed: $newStatus');

    for (final callback in _statusCallbacks) {
      callback(newStatus);
    }
  }

  /// Notify session expiry listeners
  void _notifyExpiryCallbacks() {
    for (final callback in _expiryCallbacks) {
      callback();
    }
  }

  // ============================================================================
  // SESSION DIAGNOSTICS
  // ============================================================================

  /// Get session information for debugging
  Map<String, dynamic> getSessionInfo() {
    return {
      'status': _status.toString(),
      'isActive': isActive,
      'isAuthenticated': isAuthenticated,
      'tokenExpiryTime': _tokenExpiryTime?.toIso8601String(),
      'timeUntilExpiry': timeUntilExpiry?.toString(),
      'refreshScheduled': _refreshTimer?.isActive ?? false,
      'expiryScheduled': _expiryTimer?.isActive ?? false,
    };
  }

  /// Print session info to console
  void printSessionInfo() {
    final info = getSessionInfo();
    debugPrint('''
╔════════════════════════════════════════════════════════════════╗
║                     SESSION INFORMATION                        ║
╠════════════════════════════════════════════════════════════════╣
║ Status: ${info['status']}
║ Active: ${info['isActive']}
║ Authenticated: ${info['isAuthenticated']}
║ Token Expiry: ${info['tokenExpiryTime']}
║ Time Until Expiry: ${info['timeUntilExpiry']}
║ Refresh Scheduled: ${info['refreshScheduled']}
║ Expiry Scheduled: ${info['expiryScheduled']}
╚════════════════════════════════════════════════════════════════╝
    ''');
  }

  // ============================================================================
  // CLEANUP
  // ============================================================================

  /// Dispose session service and cleanup timers
  void dispose() {
    debugPrint('🔌 Disposing session service');
    _refreshTimer?.cancel();
    _expiryTimer?.cancel();
    _statusCallbacks.clear();
    _expiryCallbacks.clear();
  }
}
