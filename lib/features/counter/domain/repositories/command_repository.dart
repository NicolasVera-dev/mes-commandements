import 'dart:async';

import '../entities/command.dart';

/// Repository pour charger et synchroniser l'ensemble des commandements.
abstract class CommandRepository {
  Stream<List<Command>> watchAll();

  Future<void> add(Command command);

  Future<void> update(Command command);

  Future<void> delete(String commandId);

  Future<void> incrementProgress(String commandId);

  Future<void> resetProgress(String commandId);
}

