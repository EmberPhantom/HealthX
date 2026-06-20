import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/notification_preferences_service.dart';
import '../../../core/services/water_reminder_service.dart';
import '../../../main.dart' show pushNotificationServiceProvider;

class NotificationPreferencesState {
  final Map<String, bool> prefs;
  final bool isLoading;

  const NotificationPreferencesState({
    this.prefs = const {},
    this.isLoading = true,
  });

  bool get waterReminders => prefs['water_reminders'] ?? true;
  bool get sleepAlarms => prefs['sleep_alarms'] ?? true;
  bool get healthAlerts => prefs['health_alerts'] ?? true;
  bool get orderUpdates => prefs['order_updates'] ?? true;
  bool get promotionsOffers => prefs['promotions_offers'] ?? false;

  NotificationPreferencesState copyWith({
    Map<String, bool>? prefs,
    bool? isLoading,
  }) {
    return NotificationPreferencesState(
      prefs: prefs ?? this.prefs,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class NotificationPreferencesNotifier
    extends Notifier<NotificationPreferencesState> {
  final NotificationPreferencesService _service =
      NotificationPreferencesService();

  @override
  NotificationPreferencesState build() {
    Future.microtask(() => _load());
    return const NotificationPreferencesState();
  }

  Future<void> _load() async {
    final prefs = await _service.loadAll();
    state = NotificationPreferencesState(prefs: prefs, isLoading: false);
  }

  Future<void> toggle(String key, bool value) async {
    await _service.set(key, value);
    state = state.copyWith(
      prefs: {...state.prefs, key: value},
    );

    if (key == 'water_reminders') {
      final waterService = WaterReminderService(
        ref.read(pushNotificationServiceProvider),
      );
      if (value) {
        await waterService.scheduleAll();
      } else {
        await waterService.cancelAll();
      }
    }
  }
}

final notificationPreferencesProvider = NotifierProvider<
    NotificationPreferencesNotifier, NotificationPreferencesState>(
  NotificationPreferencesNotifier.new,
);
