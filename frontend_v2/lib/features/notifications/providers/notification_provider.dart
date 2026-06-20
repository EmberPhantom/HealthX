import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../../../core/models/notification_models.dart';
import '../../auth/providers/auth_provider.dart';

class NotificationState {
  final List<NotificationModel> notifications;
  final bool isLoading;
  final String? error;
  final int unreadCount;

  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
    this.unreadCount = 0,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
    String? error,
    int? unreadCount,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class NotificationNotifier extends Notifier<NotificationState> {
  final NotificationService _service = NotificationService();
  Timer? _pollingTimer;

  @override
  NotificationState build() {
    final session = ref.watch(sessionProvider);
    if (session != null) {
      Future.microtask(() => fetchNotifications());
      _startPolling();
    } else {
      _stopPolling();
    }

    // Cleanup timer when the provider is disposed
    ref.onDispose(_stopPolling);

    return const NotificationState();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    // Refresh unread count every 60 seconds while the app is active
    _pollingTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _refreshUnreadCount();
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _service.getNotifications(),
        _service.getUnreadCount(),
      ]);
      state = NotificationState(
        notifications: results[0] as List<NotificationModel>,
        unreadCount: results[1] as int,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> _refreshUnreadCount() async {
    try {
      final count = await _service.getUnreadCount();
      state = state.copyWith(unreadCount: count);
    } catch (_) {}
  }

  Future<void> markAsRead(String id) async {
    try {
      await _service.markAsRead(id);
      final updatedList = state.notifications.map((n) {
        if (n.id == id) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();
      final newUnread = (state.unreadCount - 1).clamp(0, 9999);
      state = state.copyWith(notifications: updatedList, unreadCount: newUnread);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> markAllRead() async {
    try {
      await _service.markAllRead();
      final updatedList = state.notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      state = state.copyWith(notifications: updatedList, unreadCount: 0);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _service.deleteNotification(id);
      final updatedList = state.notifications.where((n) => n.id != id).toList();
      // Recalculate unread count from remaining list
      final unread = updatedList.where((n) => !n.isRead).length;
      state = state.copyWith(notifications: updatedList, unreadCount: unread);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final notificationProvider = NotifierProvider<NotificationNotifier, NotificationState>(
  NotificationNotifier.new,
);
