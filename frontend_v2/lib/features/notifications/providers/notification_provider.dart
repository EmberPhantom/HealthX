import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../../../core/models/notification_models.dart';

class NotificationState {
  final List<NotificationModel> notifications;
  final bool isLoading;
  final String? error;

  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class NotificationNotifier extends Notifier<NotificationState> {
  final NotificationService _service = NotificationService();

  @override
  NotificationState build() {
    Future.microtask(() => fetchNotifications());
    return const NotificationState();
  }

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _service.getNotifications();
      state = NotificationState(
        notifications: list,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> markAsRead(String id) async {
    final success = await _service.markAsRead(id);
    if (success) {
      final updatedList = state.notifications.map((n) {
        if (n.id == id) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();
      state = state.copyWith(notifications: updatedList);
    }
  }

  Future<void> deleteNotification(String id) async {
    final success = await _service.deleteNotification(id);
    if (success) {
      final updatedList = state.notifications.where((n) => n.id != id).toList();
      state = state.copyWith(notifications: updatedList);
    }
  }
}

final notificationProvider = NotifierProvider<NotificationNotifier, NotificationState>(
  NotificationNotifier.new,
);
