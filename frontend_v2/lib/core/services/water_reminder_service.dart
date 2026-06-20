import 'push_notification_service.dart';

class WaterReminderService {
  final PushNotificationService _pushService;

  WaterReminderService(this._pushService);

  static const int _baseNotifId = 2001;
  static const int _intervalMinutes = 30;
  static const int _startHour = 8;
  static const int _endHour = 21; // 9 PM

  int get _slotCount =>
      ((_endHour - _startHour) * 60) ~/ _intervalMinutes;

  Future<void> scheduleAll() async {
    await cancelAll();
    final now = DateTime.now();
    int slotIndex = 0;

    for (int hour = _startHour; hour < _endHour; hour++) {
      for (int minute = 0; minute < 60; minute += _intervalMinutes) {
        if (slotIndex >= _slotCount) break;
        final id = _baseNotifId + slotIndex;
        final scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);

        if (scheduledTime.isAfter(now)) {
          await _pushService.scheduleLocalNotification(
            id: id,
            title: 'Time to Hydrate!',
            body: 'Stay refreshed! Drink a glass of water to meet your daily hydration goal. 💧',
            hour: hour,
            minute: minute,
          );
        }
        slotIndex++;
      }
    }
  }

  Future<void> cancelAll() async {
    for (int i = 0; i < _slotCount; i++) {
      await _pushService.cancelScheduledNotification(_baseNotifId + i);
    }
  }
}
