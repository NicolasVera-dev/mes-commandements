import '../../commands/domain/entities/command.dart';

/// Planification des rappels locaux (annulation, replanification, permission OS).
abstract class NotificationScheduler {
  Future<void> rescheduleAll(List<Command> commands);

  Future<void> cancelAll();

  Future<void> requestPermission();
}

/// Implémentation sans effet (tests, plateformes non supportées).
class NoOpNotificationScheduler implements NotificationScheduler {
  const NoOpNotificationScheduler();

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> requestPermission() async {}

  @override
  Future<void> rescheduleAll(List<Command> commands) async {}
}
