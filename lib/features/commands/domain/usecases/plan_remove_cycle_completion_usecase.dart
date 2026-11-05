import '../entities/command.dart';
import '../services/cycle_key_generator.dart';

enum RemoveCycleCompletionRejectionReason {
  invalidCycleKey,
  cycleNotCompleted,
  currentCycle,
  futureCycle,
}

class RemoveCycleCompletionPlan {
  final String cycleKey;

  const RemoveCycleCompletionPlan({required this.cycleKey});
}

class RemoveCycleCompletionRejected implements Exception {
  final RemoveCycleCompletionRejectionReason reason;

  const RemoveCycleCompletionRejected(this.reason);
}

class PlanRemoveCycleCompletionUseCase {
  const PlanRemoveCycleCompletionUseCase();

  RemoveCycleCompletionPlan execute({
    required Frequency frequency,
    required String cycleKey,
    required bool isAlreadyCompleted,
    DateTime? nowUtc,
  }) {
    final now = (nowUtc ?? DateTime.now()).toUtc();
    final normalizedCycleKey = _normalizeCycleKey(
      frequency: frequency,
      cycleKey: cycleKey,
    );
    if (normalizedCycleKey == null) {
      throw const RemoveCycleCompletionRejected(
        RemoveCycleCompletionRejectionReason.invalidCycleKey,
      );
    }
    if (!isAlreadyCompleted) {
      throw const RemoveCycleCompletionRejected(
        RemoveCycleCompletionRejectionReason.cycleNotCompleted,
      );
    }

    final currentKey = CycleKeyGenerator.forFrequency(
      frequency: frequency,
      atUtc: now,
    );
    if (normalizedCycleKey == currentKey) {
      throw const RemoveCycleCompletionRejected(
        RemoveCycleCompletionRejectionReason.currentCycle,
      );
    }
    if (_isFutureCycle(
      frequency: frequency,
      cycleKey: normalizedCycleKey,
      currentKey: currentKey,
    )) {
      throw const RemoveCycleCompletionRejected(
        RemoveCycleCompletionRejectionReason.futureCycle,
      );
    }

    return RemoveCycleCompletionPlan(cycleKey: normalizedCycleKey);
  }

  bool _isFutureCycle({
    required Frequency frequency,
    required String cycleKey,
    required String currentKey,
  }) {
    return switch (frequency) {
      Frequency.daily => cycleKey.compareTo(currentKey) > 0,
      Frequency.weekly => cycleKey.compareTo(currentKey) > 0,
      Frequency.monthly => cycleKey.compareTo(currentKey) > 0,
      Frequency.yearly => int.parse(cycleKey) > int.parse(currentKey),
    };
  }

  String? _normalizeCycleKey({
    required Frequency frequency,
    required String cycleKey,
  }) {
    final raw = cycleKey.trim();
    if (raw.isEmpty) return null;
    return switch (frequency) {
      Frequency.daily =>
        RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw) ? raw : null,
      Frequency.weekly => _normalizeWeeklyCycleKey(raw),
      Frequency.monthly => RegExp(r'^\d{4}-\d{2}$').hasMatch(raw) ? raw : null,
      Frequency.yearly => RegExp(r'^\d{4}$').hasMatch(raw) ? raw : null,
    };
  }

  String? _normalizeWeeklyCycleKey(String cycleKey) {
    final match = RegExp(r'^(\d{4})-[SW](\d{2})$').firstMatch(cycleKey);
    if (match == null) return null;
    final week = int.parse(match.group(2)!);
    if (week < 1 || week > 53) return null;
    return '${match.group(1)}-S${match.group(2)}';
  }
}
