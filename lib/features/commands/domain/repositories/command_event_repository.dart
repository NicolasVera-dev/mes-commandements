import 'dart:async';

import '../entities/command_event.dart';
import '../entities/command_events_period.dart';

abstract class CommandEventRepository {
  /// Flux temps réel des événements d'un commandement sur une période.
  /// Si `period` est null, le mois courant est utilisé.
  Stream<List<CommandEvent>> watchEvents(
    String commandId, {
    CommandEventsPeriod? period,
  });

  /// Tous les événements depuis [startUtcInclusive] (pour séries globales, ex. badge).
  Stream<List<CommandEvent>> watchEventsFrom(
    String commandId, {
    required DateTime startUtcInclusive,
  });

  /// Ajout non bloquant (fire-and-forget) d'un événement.
  void addEventFireAndForget({
    required String commandId,
    required CommandEvent event,
  });

  /// Supprime tous les événements d'un commandement (RGPD).
  Future<void> deleteAllEvents(String commandId);

  /// Retourne la date UTC du premier événement enregistré, si disponible.
  Future<DateTime?> firstEventAtUtc(String commandId);
}
