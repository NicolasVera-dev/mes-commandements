import 'package:flutter_test/flutter_test.dart';
import 'package:rituel/features/commands/domain/entities/command.dart';
import 'package:rituel/features/commands/domain/entities/command_event.dart';
import 'package:rituel/features/commands/domain/services/cycle_key_generator.dart';
import 'package:rituel/features/commands/domain/usecases/build_cycle_summary_usecase.dart';

void main() {
  group('BuildCycleSummaryUseCase', () {
    const useCase = BuildCycleSummaryUseCase();

    CommandEvent event({
      required CommandEventType type,
      required String cycleKey,
      int progressAfterAction = 1,
      int targetAtAction = 5,
    }) {
      return CommandEvent(
        type: type,
        actionAtUtc: DateTime.utc(2026, 3, 1),
        progressAfterAction: progressAfterAction,
        targetAtAction: targetAtAction,
        cycleKey: cycleKey,
      );
    }

    group('entrée grouped vide (aucune clé avec événements)', () {
      test('daily compte succès 0 et échecs sur jours passés visibles', () {
        final summary = useCase.execute(
          frequency: Frequency.daily,
          anchorUtc: DateTime.utc(2026, 3, 1),
          grouped: const {},
          currentKey: '2026-03-15',
          createdAtUtc: DateTime.utc(2026, 3, 10),
          nowUtc: DateTime.utc(2026, 3, 15, 12),
        );
        expect(summary.success, 0);
        // Jours visibles 10–14 inclus = 5 jours passés avant le 15 courant.
        expect(summary.failed, 5);
        expect(summary.total, 5);
      });
    });

    group('un seul cycle avec événements', () {
      test('daily un jour avec complete → 1 succès 0 échec', () {
        final summary = useCase.execute(
          frequency: Frequency.daily,
          anchorUtc: DateTime.utc(2026, 3, 1),
          grouped: {
            '2026-03-12': [
              event(type: CommandEventType.complete, cycleKey: '2026-03-12'),
            ],
          },
          currentKey: '2026-03-15',
          createdAtUtc: DateTime.utc(2026, 3, 10),
          nowUtc: DateTime.utc(2026, 3, 15, 12),
        );
        expect(summary.success, 1);
        expect(summary.failed, 4);
      });
    });

    group('cas limites progressAfterAction sur événements (sans type complete)', () {
      test('progressAfterAction == 0 et targetAtAction > 0 : jour passé sans complete compte en échec', () {
        final summary = useCase.execute(
          frequency: Frequency.daily,
          anchorUtc: DateTime.utc(2026, 3, 1),
          grouped: {
            '2026-03-11': [
              event(
                type: CommandEventType.increment,
                cycleKey: '2026-03-11',
                progressAfterAction: 0,
                targetAtAction: 5,
              ),
            ],
          },
          currentKey: '2026-03-15',
          createdAtUtc: DateTime.utc(2026, 3, 10),
          nowUtc: DateTime.utc(2026, 3, 15, 12),
        );
        expect(summary.success, 0);
        expect(summary.failed, greaterThanOrEqualTo(1));
      });

      test('progressAfterAction == target - 1 : pas de complete → échec si jour passé', () {
        final summary = useCase.execute(
          frequency: Frequency.daily,
          anchorUtc: DateTime.utc(2026, 3, 1),
          grouped: {
            '2026-03-11': [
              event(
                type: CommandEventType.increment,
                cycleKey: '2026-03-11',
                progressAfterAction: 4,
                targetAtAction: 5,
              ),
            ],
          },
          currentKey: '2026-03-15',
          createdAtUtc: DateTime.utc(2026, 3, 10),
          nowUtc: DateTime.utc(2026, 3, 15, 12),
        );
        expect(summary.success, 0);
        expect(summary.failed, greaterThanOrEqualTo(1));
      });

      test('progressAfterAction == target mais type increment : pas succès, jour passé → échec', () {
        final summary = useCase.execute(
          frequency: Frequency.daily,
          anchorUtc: DateTime.utc(2026, 3, 1),
          grouped: {
            '2026-03-11': [
              event(
                type: CommandEventType.increment,
                cycleKey: '2026-03-11',
                progressAfterAction: 5,
                targetAtAction: 5,
              ),
            ],
          },
          currentKey: '2026-03-15',
          createdAtUtc: DateTime.utc(2026, 3, 10),
          nowUtc: DateTime.utc(2026, 3, 15, 12),
        );
        expect(summary.success, 0);
        expect(summary.failed, greaterThanOrEqualTo(1));
      });

      test('type complete avec progressAfterAction == target → succès', () {
        final summary = useCase.execute(
          frequency: Frequency.daily,
          anchorUtc: DateTime.utc(2026, 3, 1),
          grouped: {
            '2026-03-12': [
              event(
                type: CommandEventType.complete,
                cycleKey: '2026-03-12',
                progressAfterAction: 5,
                targetAtAction: 5,
              ),
            ],
          },
          currentKey: '2026-03-15',
          createdAtUtc: DateTime.utc(2026, 3, 10),
          nowUtc: DateTime.utc(2026, 3, 15, 12),
        );
        expect(summary.success, 1);
      });
    });

    group('Frequency.daily', () {
      test('mois entier avec createdAt 1er : nombre de jours cohérent', () {
        final summary = useCase.execute(
          frequency: Frequency.daily,
          anchorUtc: DateTime.utc(2026, 3, 1),
          grouped: const {},
          currentKey: '2026-03-31',
          createdAtUtc: DateTime.utc(2026, 3, 1),
          nowUtc: DateTime.utc(2026, 3, 31),
        );
        // Mars 31 jours, jour courant exclu des « passés » pour failed daily.
        expect(summary.failed, 30);
        expect(summary.success, 0);
      });
    });

    group('Frequency.weekly', () {
      test('cycle courant avec complete → succès', () {
        const key = '2026-S13';
        final summary = useCase.execute(
          frequency: Frequency.weekly,
          anchorUtc: DateTime.utc(2026, 3, 1),
          grouped: {
            key: [event(type: CommandEventType.complete, cycleKey: key)],
          },
          currentKey: key,
          createdAtUtc: DateTime.utc(2026, 2, 1),
          nowUtc: DateTime.utc(2026, 3, 26, 12),
        );
        expect(summary.success, greaterThanOrEqualTo(1));
      });

      test('semaines sans événements : échecs sur périodes passées', () {
        final summary = useCase.execute(
          frequency: Frequency.weekly,
          anchorUtc: DateTime.utc(2026, 3, 1),
          grouped: const {},
          currentKey: CycleKeyGenerator.forFrequency(
            frequency: Frequency.weekly,
            atUtc: DateTime.utc(2026, 3, 26),
          ),
          createdAtUtc: DateTime.utc(2026, 3, 1),
          nowUtc: DateTime.utc(2026, 3, 26, 12),
        );
        expect(summary.success, 0);
        expect(summary.failed, greaterThan(0));
      });
    });

    group('Frequency.monthly', () {
      test('année 2026 : mois avant createdAt exclus, passés sans complete en échec', () {
        final summary = useCase.execute(
          frequency: Frequency.monthly,
          anchorUtc: DateTime.utc(2026, 1, 1),
          grouped: const {},
          currentKey: '2026-06',
          createdAtUtc: DateTime.utc(2026, 4, 10),
          nowUtc: DateTime.utc(2026, 6, 15),
        );
        expect(summary.success, 0);
        // Mois visibles : avril, mai ; juin courant non « passé » pour failed.
        expect(summary.failed, 2);
      });

      test('un mois avec complete → 1 succès', () {
        final summary = useCase.execute(
          frequency: Frequency.monthly,
          anchorUtc: DateTime.utc(2026, 1, 1),
          grouped: {
            '2026-04': [
              event(type: CommandEventType.complete, cycleKey: '2026-04'),
            ],
          },
          currentKey: '2026-06',
          createdAtUtc: DateTime.utc(2026, 4, 1),
          nowUtc: DateTime.utc(2026, 6, 15),
        );
        expect(summary.success, 1);
      });
    });

    group('Frequency.yearly', () {
      test('année visible seule sans événement et année passée vs now → 0 succès 0 failed si année courante', () {
        final summary = useCase.execute(
          frequency: Frequency.yearly,
          anchorUtc: DateTime.utc(2026, 1, 1),
          grouped: const {},
          currentKey: '2026',
          createdAtUtc: DateTime.utc(2026, 1, 1),
          nowUtc: DateTime.utc(2026, 6, 1),
        );
        expect(summary.success, 0);
        expect(summary.failed, 0);
        expect(summary.total, 0);
      });

      test('année précédente sans complete → failed', () {
        final summary = useCase.execute(
          frequency: Frequency.yearly,
          anchorUtc: DateTime.utc(2025, 1, 1),
          grouped: const {},
          currentKey: '2025',
          createdAtUtc: DateTime.utc(2020, 1, 1),
          nowUtc: DateTime.utc(2026, 6, 1),
        );
        expect(summary.success, 0);
        expect(summary.failed, 1);
      });

      test('année avec complete → succès', () {
        final summary = useCase.execute(
          frequency: Frequency.yearly,
          anchorUtc: DateTime.utc(2025, 1, 1),
          grouped: {
            '2025': [event(type: CommandEventType.complete, cycleKey: '2025')],
          },
          currentKey: '2025',
          createdAtUtc: DateTime.utc(2020, 1, 1),
          nowUtc: DateTime.utc(2026, 6, 1),
        );
        expect(summary.success, 1);
        expect(summary.failed, 0);
      });
    });
  });
}
