import 'package:flutter_test/flutter_test.dart';
import 'package:mes_commandements/features/counter/domain/entities/command.dart';

void main() {
  Command buildCommand({
    required Frequency frequency,
    required DateTime? lastResetDate,
    int progress = 3,
  }) {
    return Command(
      id: 'c1',
      title: 'Test',
      target: 10,
      progress: progress,
      frequency: frequency,
      lastResetAt: lastResetDate,
    );
  }

  group('Command.shouldAutoReset', () {
    group('daily', () {
      final today = DateTime.utc(2026, 3, 25, 12, 0, 0);

      test('doit resetter si lastResetDate = hier (J-1)', () {
        expect(
          buildCommand(
            frequency: Frequency.daily,
            lastResetDate: DateTime.utc(2026, 3, 24, 12, 0, 0),
          ).shouldAutoReset(today),
          isTrue,
        );
      });

      test('doit resetter si lastResetDate = il y a 2 jours (J-2)', () {
        expect(
          buildCommand(
            frequency: Frequency.daily,
            lastResetDate: DateTime.utc(2026, 3, 23, 12, 0, 0),
          ).shouldAutoReset(today),
          isTrue,
        );
      });

      test('doit resetter si lastResetDate = il y a 3 jours (J-3)', () {
        expect(
          buildCommand(
            frequency: Frequency.daily,
            lastResetDate: DateTime.utc(2026, 3, 22, 12, 0, 0),
          ).shouldAutoReset(today),
          isTrue,
        );
      });

      test('doit resetter si lastResetDate = il y a 1 an', () {
        expect(
          buildCommand(
            frequency: Frequency.daily,
            lastResetDate: DateTime.utc(2025, 3, 25, 12, 0, 0),
          ).shouldAutoReset(today),
          isTrue,
        );
      });

      test(
          'doit resetter si lastResetDate = 31 décembre année précédente (changement année)',
          () {
        expect(
          buildCommand(
            frequency: Frequency.daily,
            lastResetDate: DateTime.utc(2025, 12, 31, 23, 59, 59),
          ).shouldAutoReset(today),
          isTrue,
        );
      });

      test('doit resetter si lastResetDate = il y a 1 mois', () {
        expect(
          buildCommand(
            frequency: Frequency.daily,
            lastResetDate: DateTime.utc(2026, 2, 25, 12, 0, 0),
          ).shouldAutoReset(today),
          isTrue,
        );
      });

      test('ne doit pas resetter si lastResetDate = aujourd\'hui (même heure)',
          () {
        expect(
          buildCommand(
            frequency: Frequency.daily,
            lastResetDate: DateTime.utc(2026, 3, 25, 12, 0, 0),
          ).shouldAutoReset(today),
          isFalse,
        );
      });

      test('ne doit pas resetter si lastResetDate = aujourd\'hui à minuit', () {
        expect(
          buildCommand(
            frequency: Frequency.daily,
            lastResetDate: DateTime.utc(2026, 3, 25, 0, 0, 0),
          ).shouldAutoReset(today),
          isFalse,
        );
      });

      test('ne doit pas resetter si lastResetDate = aujourd\'hui à 23h59', () {
        expect(
          buildCommand(
            frequency: Frequency.daily,
            lastResetDate: DateTime.utc(2026, 3, 25, 23, 59, 0),
          ).shouldAutoReset(today),
          isFalse,
        );
      });
    });

    group('weekly', () {
      final todayWednesday = DateTime.utc(2026, 3, 25, 12, 0, 0); // mercredi
      final mondayCurrentWeek = DateTime.utc(2026, 3, 23, 0, 0, 0);

      test('doit resetter si lastResetDate = lundi de la semaine dernière', () {
        expect(
          buildCommand(
            frequency: Frequency.weekly,
            lastResetDate: DateTime.utc(2026, 3, 16, 8, 0, 0),
          ).shouldAutoReset(todayWednesday),
          isTrue,
        );
      });

      test(
          'doit resetter si lastResetDate = dimanche de la semaine dernière (veille lundi courant)',
          () {
        expect(
          buildCommand(
            frequency: Frequency.weekly,
            lastResetDate: DateTime.utc(2026, 3, 22, 23, 59, 59),
          ).shouldAutoReset(todayWednesday),
          isTrue,
        );
      });

      test('doit resetter si lastResetDate = il y a 2 semaines', () {
        expect(
          buildCommand(
            frequency: Frequency.weekly,
            lastResetDate: DateTime.utc(2026, 3, 9, 10, 0, 0),
          ).shouldAutoReset(todayWednesday),
          isTrue,
        );
      });

      test('doit resetter si lastResetDate = il y a 1 an', () {
        expect(
          buildCommand(
            frequency: Frequency.weekly,
            lastResetDate: DateTime.utc(2025, 3, 25, 12, 0, 0),
          ).shouldAutoReset(todayWednesday),
          isTrue,
        );
      });

      test(
          'doit resetter si lastResetDate = semaine 52 année dernière (changement année)',
          () {
        final now = DateTime.utc(2026, 1, 6, 12, 0, 0); // mardi, lundi courant=2026-01-05
        expect(
          buildCommand(
            frequency: Frequency.weekly,
            lastResetDate: DateTime.utc(2025, 12, 28, 12, 0, 0),
          ).shouldAutoReset(now),
          isTrue,
        );
      });

      test('ne doit pas resetter si lastResetDate = lundi semaine en cours', () {
        expect(
          buildCommand(
            frequency: Frequency.weekly,
            lastResetDate: mondayCurrentWeek,
          ).shouldAutoReset(todayWednesday),
          isFalse,
        );
      });

      test('ne doit pas resetter si lastResetDate = mercredi semaine en cours',
          () {
        expect(
          buildCommand(
            frequency: Frequency.weekly,
            lastResetDate: DateTime.utc(2026, 3, 25, 9, 0, 0),
          ).shouldAutoReset(todayWednesday),
          isFalse,
        );
      });

      test('ne doit pas resetter si lastResetDate = dimanche semaine en cours',
          () {
        final now = DateTime.utc(2026, 3, 29, 15, 0, 0); // dimanche
        expect(
          buildCommand(
            frequency: Frequency.weekly,
            lastResetDate: DateTime.utc(2026, 3, 29, 8, 0, 0),
          ).shouldAutoReset(now),
          isFalse,
        );
      });

      test(
          'ne doit pas resetter si aujourd\'hui est lundi et lastResetDate = ce matin',
          () {
        final mondayMorning = DateTime.utc(2026, 3, 23, 10, 0, 0);
        expect(
          buildCommand(
            frequency: Frequency.weekly,
            lastResetDate: DateTime.utc(2026, 3, 23, 7, 0, 0),
          ).shouldAutoReset(mondayMorning),
          isFalse,
        );
      });
    });

    group('monthly', () {
      final today = DateTime.utc(2026, 3, 25, 12, 0, 0);

      test('doit resetter si lastResetDate = 1er du mois dernier', () {
        expect(
          buildCommand(
            frequency: Frequency.monthly,
            lastResetDate: DateTime.utc(2026, 2, 1, 0, 0, 0),
          ).shouldAutoReset(today),
          isTrue,
        );
      });

      test(
          'doit resetter si lastResetDate = dernier jour du mois précédent (28/29/30/31)',
          () {
        expect(
          buildCommand(
            frequency: Frequency.monthly,
            lastResetDate: DateTime.utc(2026, 2, 28, 23, 59, 59),
          ).shouldAutoReset(today),
          isTrue,
        );
      });

      test('doit resetter si lastResetDate = il y a 2 mois', () {
        expect(
          buildCommand(
            frequency: Frequency.monthly,
            lastResetDate: DateTime.utc(2026, 1, 25, 12, 0, 0),
          ).shouldAutoReset(today),
          isTrue,
        );
      });

      test('doit resetter si lastResetDate = il y a 1 an', () {
        expect(
          buildCommand(
            frequency: Frequency.monthly,
            lastResetDate: DateTime.utc(2025, 3, 25, 12, 0, 0),
          ).shouldAutoReset(today),
          isTrue,
        );
      });

      test(
          'doit resetter si lastResetDate = décembre année précédente (changement année)',
          () {
        final now = DateTime.utc(2026, 1, 15, 12, 0, 0);
        expect(
          buildCommand(
            frequency: Frequency.monthly,
            lastResetDate: DateTime.utc(2025, 12, 31, 12, 0, 0),
          ).shouldAutoReset(now),
          isTrue,
        );
      });

      test('ne doit pas resetter si lastResetDate = 1er du mois en cours', () {
        expect(
          buildCommand(
            frequency: Frequency.monthly,
            lastResetDate: DateTime.utc(2026, 3, 1, 0, 0, 0),
          ).shouldAutoReset(today),
          isFalse,
        );
      });

      test('ne doit pas resetter si lastResetDate = aujourd\'hui (milieu mois)',
          () {
        expect(
          buildCommand(
            frequency: Frequency.monthly,
            lastResetDate: DateTime.utc(2026, 3, 25, 12, 0, 0),
          ).shouldAutoReset(today),
          isFalse,
        );
      });

      test('ne doit pas resetter si lastResetDate = hier mais même mois', () {
        expect(
          buildCommand(
            frequency: Frequency.monthly,
            lastResetDate: DateTime.utc(2026, 3, 24, 23, 0, 0),
          ).shouldAutoReset(today),
          isFalse,
        );
      });
    });

    group('yearly', () {
      final today = DateTime.utc(2026, 3, 25, 12, 0, 0);

      test('doit resetter si lastResetDate = 31 décembre année précédente', () {
        expect(
          buildCommand(
            frequency: Frequency.yearly,
            lastResetDate: DateTime.utc(2025, 12, 31, 23, 59, 59),
          ).shouldAutoReset(today),
          isTrue,
        );
      });

      test('doit resetter si lastResetDate = 1er janvier année précédente', () {
        expect(
          buildCommand(
            frequency: Frequency.yearly,
            lastResetDate: DateTime.utc(2025, 1, 1, 0, 0, 0),
          ).shouldAutoReset(today),
          isTrue,
        );
      });

      test('doit resetter si lastResetDate = il y a 2 ans', () {
        expect(
          buildCommand(
            frequency: Frequency.yearly,
            lastResetDate: DateTime.utc(2024, 3, 25, 12, 0, 0),
          ).shouldAutoReset(today),
          isTrue,
        );
      });

      test('doit resetter si lastResetDate = 1er juillet année précédente', () {
        expect(
          buildCommand(
            frequency: Frequency.yearly,
            lastResetDate: DateTime.utc(2025, 7, 1, 0, 0, 0),
          ).shouldAutoReset(today),
          isTrue,
        );
      });

      test('ne doit pas resetter si lastResetDate = 1er janvier année en cours',
          () {
        expect(
          buildCommand(
            frequency: Frequency.yearly,
            lastResetDate: DateTime.utc(2026, 1, 1, 0, 0, 0),
          ).shouldAutoReset(today),
          isFalse,
        );
      });

      test('ne doit pas resetter si lastResetDate = hier mais même année', () {
        expect(
          buildCommand(
            frequency: Frequency.yearly,
            lastResetDate: DateTime.utc(2026, 3, 24, 12, 0, 0),
          ).shouldAutoReset(today),
          isFalse,
        );
      });

      test('ne doit pas resetter si lastResetDate = aujourd\'hui', () {
        expect(
          buildCommand(
            frequency: Frequency.yearly,
            lastResetDate: DateTime.utc(2026, 3, 25, 12, 0, 0),
          ).shouldAutoReset(today),
          isFalse,
        );
      });
    });

    group('cas limites transversaux', () {
      final now = DateTime.utc(2026, 3, 25, 12, 0, 0);

      test('lastResetDate = null -> reset pour toutes les fréquences', () {
        for (final frequency in Frequency.values) {
          expect(
            buildCommand(frequency: frequency, lastResetDate: null)
                .shouldAutoReset(now),
            isTrue,
            reason: 'Fréquence ${frequency.name} devrait resetter si null',
          );
        }
      });

      test('lastResetDate dans le futur -> ne reset pas', () {
        final future = DateTime.utc(2026, 3, 26, 0, 0, 0);
        for (final frequency in Frequency.values) {
          expect(
            buildCommand(frequency: frequency, lastResetDate: future)
                .shouldAutoReset(now),
            isFalse,
            reason: 'Fréquence ${frequency.name} ne doit pas resetter dans le futur',
          );
        }
      });

      test(
          'changement heure été/hiver -> daily reste basé sur le jour civil UTC',
          () {
        final dstBoundaryNow = DateTime.utc(2026, 3, 29, 12, 0, 0);
        expect(
          buildCommand(
            frequency: Frequency.daily,
            lastResetDate: DateTime.utc(2026, 3, 28, 23, 30, 0),
          ).shouldAutoReset(dstBoundaryNow),
          isTrue,
        );
      });

      test('29 février année bissextile -> monthly et yearly corrects', () {
        final now = DateTime.utc(2024, 3, 1, 10, 0, 0);
        expect(
          buildCommand(
            frequency: Frequency.monthly,
            lastResetDate: DateTime.utc(2024, 2, 29, 23, 59, 0),
          ).shouldAutoReset(now),
          isTrue,
        );

        expect(
          buildCommand(
            frequency: Frequency.yearly,
            lastResetDate: DateTime.utc(2024, 2, 29, 12, 0, 0),
          ).shouldAutoReset(DateTime.utc(2024, 12, 31, 12, 0, 0)),
          isFalse,
        );
      });
    });

    group('scénarios de régression', () {
      test('lastResetDate il y a 3 jours: daily oui, autres non même période',
          () {
        final now = DateTime.utc(2026, 3, 26, 12, 0, 0); // jeudi
        final lastResetDate = DateTime.utc(2026, 3, 23, 12, 0, 0); // lundi

        expect(
          buildCommand(
            frequency: Frequency.daily,
            lastResetDate: lastResetDate,
          ).shouldAutoReset(now),
          isTrue,
        );
        expect(
          buildCommand(
            frequency: Frequency.weekly,
            lastResetDate: lastResetDate,
          ).shouldAutoReset(now),
          isFalse,
        );
        expect(
          buildCommand(
            frequency: Frequency.monthly,
            lastResetDate: lastResetDate,
          ).shouldAutoReset(now),
          isFalse,
        );
        expect(
          buildCommand(
            frequency: Frequency.yearly,
            lastResetDate: lastResetDate,
          ).shouldAutoReset(now),
          isFalse,
        );
      });

      test('lastResetDate il y a exactement 1 an: toutes les fréquences reset',
          () {
        final now = DateTime.utc(2026, 3, 25, 12, 0, 0);
        final lastResetDate = DateTime.utc(2025, 3, 25, 12, 0, 0);

        for (final frequency in Frequency.values) {
          expect(
            buildCommand(
              frequency: frequency,
              lastResetDate: lastResetDate,
            ).shouldAutoReset(now),
            isTrue,
          );
        }
      });
    });
  });

  group('Command.applyAutoResetIfNeeded', () {
    test('reset progress et met lastResetAt quand reset dû', () {
      final now = DateTime.utc(2026, 3, 25, 10, 0, 0);
      final command = buildCommand(
        frequency: Frequency.daily,
        lastResetDate: DateTime.utc(2026, 3, 24, 23, 0, 0),
        progress: 7,
      );

      final updated = command.applyAutoResetIfNeeded(now);

      expect(updated.progress, 0);
      expect(updated.lastResetAt, now);
    });

    test('retourne la même instance si reset non dû', () {
      final now = DateTime.utc(2026, 3, 25, 10, 0, 0);
      final command = buildCommand(
        frequency: Frequency.daily,
        lastResetDate: DateTime.utc(2026, 3, 25, 0, 0, 0),
      );

      final updated = command.applyAutoResetIfNeeded(now);

      expect(identical(updated, command), isTrue);
    });
  });
}
