import 'package:flutter_test/flutter_test.dart';
import 'package:rituel/features/resistances/domain/entities/resistance.dart';
import 'package:rituel/features/resistances/domain/usecases/compute_resistance_streak_usecase.dart';

void main() {
  test(
    'record stays visible after best synchronization, then stops on relapse',
    () {
      final start = DateTime.utc(2026, 11, 1);
      const useCase = ComputeResistanceStreakUseCase();
      final r = Resistance(
        id: 'r',
        title: 'Tabac',
        createdAtUtc: start,
        bestStreakDays: 5,
      );
      expect(useCase.isRecord(resistance: r, nowUtc: start), false);
      expect(
        useCase.isRecord(
          resistance: r,
          nowUtc: start.add(const Duration(days: 4)),
        ),
        false,
      );
      expect(
        useCase.isRecord(
          resistance: r,
          nowUtc: start.add(const Duration(days: 5)),
        ),
        false,
      );
      expect(
        useCase.isRecord(
          resistance: r,
          nowUtc: start.add(const Duration(days: 6)),
        ),
        true,
      );
      expect(
        useCase.isRecord(
          resistance: r.copyWith(bestStreakDays: 6, bestStreakBeforeRun: 5),
          nowUtc: start.add(const Duration(days: 6)),
        ),
        true,
      );
      expect(
        useCase.isRecord(
          resistance: r.copyWith(
            lastRelapseAtUtc: start.add(const Duration(days: 6)),
          ),
          nowUtc: start.add(const Duration(days: 6)),
        ),
        false,
      );
    },
  );
}
