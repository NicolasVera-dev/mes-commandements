import 'package:shared_preferences/shared_preferences.dart';

/// Préférences locales des rappels (activation + heure), sans Firestore.
class NotificationPreferencesService {
  NotificationPreferencesService(this._prefs);

  final SharedPreferences _prefs;

  static const String remindersEnabledKey = 'notification_reminders_enabled';
  static const String reminderHourKey = 'notification_reminder_hour';
  static const String reminderMinuteKey = 'notification_reminder_minute';

  bool get remindersEnabled => _prefs.getBool(remindersEnabledKey) ?? true;

  int get reminderHour => _prefs.getInt(reminderHourKey) ?? 18;

  int get reminderMinute => _prefs.getInt(reminderMinuteKey) ?? 0;

  Future<void> setRemindersEnabled(bool value) async {
    await _prefs.setBool(remindersEnabledKey, value);
  }

  Future<void> setReminderHourMinute(int hour, int minute) async {
    await _prefs.setInt(reminderHourKey, hour);
    await _prefs.setInt(reminderMinuteKey, minute);
  }
}
