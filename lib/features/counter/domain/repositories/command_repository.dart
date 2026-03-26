import 'dart:async';

import '../entities/auto_reset_report.dart';
import '../entities/command.dart';

/// Repository pour charger et synchroniser l'ensemble des commandements.
abstract class CommandRepository {
  Stream<List<Command>> watchAll();

  /// Applique les resets automatiques dus (si nécessaire) en écriture batch.
  /// Retourne un rapport (total + répartition par fréquence).
  Future<AutoResetReport> applyPendingAutoResets(DateTime now);

  Future<void> add(Command command);

  Future<void> update(Command command);

  Future<void> delete(String commandId);

  Future<void> incrementProgress(String commandId);

  Future<void> resetProgress(String commandId);
}

