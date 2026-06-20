import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreferencesService {
  static const String _kWaterNotif = 'water_reminders';
  static const String _kSleepNotif = 'sleep_alarms';
  static const String _kHealthAlert = 'health_alerts';
  static const String _kOrderUpdate = 'order_updates';
  static const String _kPromoNotif = 'promotions_offers';

  static const Map<String, bool> _defaults = {
    _kWaterNotif: true,
    _kSleepNotif: true,
    _kHealthAlert: true,
    _kOrderUpdate: true,
    _kPromoNotif: false,
  };

  Future<Map<String, bool>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      _kWaterNotif: prefs.getBool(_kWaterNotif) ?? _defaults[_kWaterNotif]!,
      _kSleepNotif: prefs.getBool(_kSleepNotif) ?? _defaults[_kSleepNotif]!,
      _kHealthAlert: prefs.getBool(_kHealthAlert) ?? _defaults[_kHealthAlert]!,
      _kOrderUpdate: prefs.getBool(_kOrderUpdate) ?? _defaults[_kOrderUpdate]!,
      _kPromoNotif: prefs.getBool(_kPromoNotif) ?? _defaults[_kPromoNotif]!,
    };
  }

  Future<void> set(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<bool> get(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? _defaults[key] ?? false;
  }
}
