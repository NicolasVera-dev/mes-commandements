import '../entities/command.dart';
import '../services/cycle_key_generator.dart';

enum BackfillCycleRejectionReason {
  invalidCycleKey,
  cycleAlreadyCompleted,
  currentCycle,
  futureCycle,
}

class BackfillCyclePlan {
  final String cycleKey;
  final DateTime actionAtUtc;

  const BackfillCyclePlan({required this.cycleKey, required this.actionAtUtc});
}

class BackfillCycleRejected implements Exception {
  final BackfillCycleRejectionReason reason;

  const BackfillCycleRejected(this.reason);
}

class PlanBackfillCycleCompletionUseCase {
  const PlanBackfillCycleCompletionUseCase();

  BackfillCyclePlan execute({
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
      throw const BackfillCycleRejected(
        BackfillCycleRejectionReason.invalidCycleKey,
      );
    }
    if (isAlreadyCompleted) {
      throw const BackfillCycleRejected(
        BackfillCycleRejectionReason.cycleAlreadyCompleted,
      );
    }

    final currentKey = CycleKeyGenerator.forFrequency(
      frequency: frequency,
      atUtc: now,
    );
    if (normalizedCycleKey == currentKey) {
      throw const BackfillCycleRejected(
        BackfillCycleRejectionReason.currentCycle,
      );
    }
    if (_isFutureCycle(
      frequency: frequency,
      cycleKey: normalizedCycleKey,
      currentKey: currentKey,
    )) {
      throw const BackfillCycleRejected(
        BackfillCycleRejectionReason.futureCycle,
      );
    }

    return BackfillCyclePlan(
      cycleKey: normalizedCycleKey,
      actionAtUtc: _cycleEndUtc(
        frequency: frequency,
        cycleKey: normalizedCycleKey,
      ).subtract(const Duration(seconds: 1)),
    );
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

  DateTime _cycleEndUtc({
    required Frequency frequency,
    required String cycleKey,
  }) {
    return switch (frequency) {
      Frequency.daily => DateTime.parse(
        '${cycleKey}T00:00:00Z',
      ).add(const Duration(days: 1)),
      Frequency.weekly => _weeklyCycleEnd(cycleKey),
      Frequency.monthly => _monthlyCycleEnd(cycleKey),
      Frequency.yearly => DateTime.utc(int.parse(cycleKey) + 1, 1, 1),
    };
  }

  DateTime _weeklyCycleEnd(String cycleKey) {
    final match = RegExp(r'^(\d{4})-S(\d{2})$').firstMatch(cycleKey);
    if (match == null) {
      throw const BackfillCycleRejected(
        BackfillCycleRejectionReason.invalidCycleKey,
      );
    }
    final year = int.parse(match.group(1)!);
    final week = int.parse(match.group(2)!);
    final jan4 = DateTime.utc(year, 1, 4);
    final mondayWeek1 = jan4.subtract(
      Duration(days: jan4.weekday - DateTime.monday),
    );
    final start = mondayWeek1.add(Duration(days: (week - 1) * 7));
    return start.add(const Duration(days: 7));
  }

  DateTime _monthlyCycleEnd(String cycleKey) {
    final match = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(cycleKey);
    if (match == null) {
      throw const BackfillCycleRejected(
        BackfillCycleRejectionReason.invalidCycleKey,
      );
    }
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    if (month < 1 || month > 12) {
      throw const BackfillCycleRejected(
        BackfillCycleRejectionReason.invalidCycleKey,
      );
    }
    if (month == 12) {
      return DateTime.utc(year + 1, 1, 1);
    }
    return DateTime.utc(year, month + 1, 1);
  }
}
