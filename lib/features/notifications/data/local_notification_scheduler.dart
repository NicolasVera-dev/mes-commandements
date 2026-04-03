import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../commands/domain/entities/command.dart';
import '../domain/local_notification_ids.dart';
import '../domain/notification_scheduler.dart';
import '../domain/reminder_slot_calculator.dart';
import 'notification_preferences_service.dart';

/// Planification concrète via [flutter_local_notifications].
class LocalNotificationScheduler implements NotificationScheduler {
  LocalNotificationScheduler({
    required FlutterLocalNotificationsPlugin plugin,
    required NotificationPreferencesService preferences,
    ReminderSlotCalculator calculator = const ReminderSlotCalculator(),
  })  : _plugin = plugin,
        _preferences = preferences,
        _calculator = calculator;

  final FlutterLocalNotificationsPlugin _plugin;
  final NotificationPreferencesService _preferences;
  final ReminderSlotCalculator _calculator;

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'command_reminders',
    'Rappels',
    description: 'Rappels discrets pour vos commandements en cours',
    importance: Importance.defaultImportance,
  );

  static Future<void> initializePlugin(FlutterLocalNotificationsPlugin plugin) async {
    await plugin.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: const DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        macOS: const DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_androidChannel);
  }

  bool get _canSchedule {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  @override
  Future<void> cancelAll() async {
    if (kIsWeb) {
      return;
    }
    await _plugin.cancelAllPendingNotifications();
  }

  @override
  Future<void> requestPermission() async {
    if (kIsWeb || !_canSchedule) {
      return;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (defaultTargetPlatform == TargetPlatform.macOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  @override
  Future<void> rescheduleAll(List<Command> commands) async {
    if (kIsWeb) {
      return;
    }
    try {
      await _plugin.cancelAllPendingNotifications();
      if (!_preferences.remindersEnabled) {
        return;
      }
      if (!_canSchedule) {
        return;
      }

      final now = DateTime.now();
      final hour = _preferences.reminderHour;
      final minute = _preferences.reminderMinute;
      final details = _notificationDetails();

      for (final frequency in Frequency.values) {
        final incomplete = commands
            .where(
              (c) => c.frequency == frequency && c.progress < c.target,
            )
            .toList();
        if (incomplete.isEmpty) {
          continue;
        }
        final count = incomplete.length;
        final body = _messageBody(frequency, count);
        const title = 'Rituel';

        switch (frequency) {
          case Frequency.daily:
            final slot = _calculator.nextDailySlot(now, hour, minute);
            await _plugin.zonedSchedule(
              id: LocalNotificationIds.daily,
              scheduledDate: _toLocalTzDateTime(slot),
              notificationDetails: details,
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              title: title,
              body: body,
              matchDateTimeComponents: DateTimeComponents.time,
            );
            break;
          case Frequency.weekly:
            for (final slot
                in _calculator.nextWeeklyWednesdayAndSunday(now, hour, minute)) {
              final id = slot.weekday == DateTime.wednesday
                  ? LocalNotificationIds.weeklyWednesday
                  : LocalNotificationIds.weeklySunday;
              await _plugin.zonedSchedule(
                id: id,
                scheduledDate: _toLocalTzDateTime(slot),
                notificationDetails: details,
                androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
                title: title,
                body: body,
                matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
              );
            }
            break;
          case Frequency.monthly:
            final j7 = _calculator.nextMonthlySevenDaysBeforeEnd(
              now,
              hour,
              minute,
            );
            if (j7 != null) {
              await _plugin.zonedSchedule(
                id: LocalNotificationIds.monthlySevenDaysBeforeEnd,
                scheduledDate: _toLocalTzDateTime(j7),
                notificationDetails: details,
                androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
                title: title,
                body: body,
              );
            }
            final j2 = _calculator.nextMonthlyTwoDaysBeforeEnd(
              now,
              hour,
              minute,
            );
            if (j2 != null) {
              await _plugin.zonedSchedule(
                id: LocalNotificationIds.monthlyTwoDaysBeforeEnd,
                scheduledDate: _toLocalTzDateTime(j2),
                notificationDetails: details,
                androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
                title: title,
                body: body,
              );
            }
            break;
          case Frequency.yearly:
            for (final slot in _calculator.nextYearlyNovemberAndDecemberFirst(
              now,
              hour,
              minute,
            )) {
              final id = slot.month == 11
                  ? LocalNotificationIds.yearlyNovemberFirst
                  : LocalNotificationIds.yearlyDecemberFirst;
              await _plugin.zonedSchedule(
                id: id,
                scheduledDate: _toLocalTzDateTime(slot),
                notificationDetails: details,
                androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
                title: title,
                body: body,
              );
            }
            break;
        }
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Erreur replanification notifications: $e');
        debugPrint('$st');
      }
    }
  }

  NotificationDetails _notificationDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannel.id,
        _androidChannel.name,
        channelDescription: _androidChannel.description,
        importance: _androidChannel.importance,
      ),
      iOS: const DarwinNotificationDetails(),
      macOS: const DarwinNotificationDetails(),
    );
  }

  /// [localWallClock] : date/heure « murales » dans le fuseau de l’utilisateur
  /// (ex. [DateTime] local issu des calculs de créneaux).
  tz.TZDateTime _toLocalTzDateTime(DateTime localWallClock) {
    return tz.TZDateTime.from(localWallClock, tz.local);
  }

  String _messageBody(Frequency frequency, int count) {
    final noun = count == 1 ? 'commandement' : 'commandements';
    switch (frequency) {
      case Frequency.daily:
        return '$count $noun à compléter aujourd’hui — chaque petit pas compte.';
      case Frequency.weekly:
        return '$count $noun à compléter cette semaine — vous y êtes presque.';
      case Frequency.monthly:
        return '$count $noun à compléter d’ici la fin du mois — continuez comme ça.';
      case Frequency.yearly:
        return '$count $noun à compléter sur l’année — un rythme régulier, ça paie.';
    }
  }
}
