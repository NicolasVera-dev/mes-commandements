import 'package:flutter_test/flutter_test.dart';
import 'package:mes_commandements/features/resistances/domain/entities/resistance.dart';

class _FakeTimestamp {
  final DateTime value;
  _FakeTimestamp(this.value);
  DateTime toDate() => value;
}

void main() {
  final t0 = DateTime.utc(2026, 1, 15);

  group('Validation modèle Resistance', () {
    test('échoue si titre vide', () {
      expect(
        () => Resistance(
          id: 'r1',
          title: '   ',
          createdAtUtc: t0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('échoue si titre dépasse la limite', () {
      expect(
        () => Resistance(
          id: 'r1',
          title: 'x' * (Resistance.maxTitleLength + 1),
          createdAtUtc: t0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('échoue si description dépasse la limite', () {
      expect(
        () => Resistance(
          id: 'r1',
          title: 'Titre',
          description: 'a' * (Resistance.maxDescriptionLength + 1),
          createdAtUtc: t0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('échoue si plus de 5 tags', () {
      expect(
        () => Resistance(
          id: 'r1',
          title: 'Titre',
          createdAtUtc: t0,
          tags: const ['a', 'b', 'c', 'd', 'e', 'f'],
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('échoue si bestStreakDays négatif', () {
      expect(
        () => Resistance(
          id: 'r1',
          title: 'Titre',
          createdAtUtc: t0,
          bestStreakDays: -1,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('Resistance.copyWith', () {
    test('clearLastRelapseAtUtc et clearAccentColorValue', () {
      final base = Resistance(
        id: 'r1',
        title: 'T',
        createdAtUtc: t0,
        accentColorValue: 42,
        lastRelapseAtUtc: DateTime.utc(2026, 2, 1),
      );
      final cleared = base.copyWith(
        clearLastRelapseAtUtc: true,
        clearAccentColorValue: true,
      );
      expect(cleared.lastRelapseAtUtc, isNull);
      expect(cleared.accentColorValue, isNull);
    });
  });

  group('Rétrocompatibilité Resistance.fromMap', () {
    test('title et description sont clampés aux limites', () {
      final r = Resistance.fromMap(
        id: 'r2',
        map: <String, Object?>{
          'title': 'x' * 80,
          'description': 'y' * (Resistance.maxDescriptionLength + 1),
          'createdAtUtc': '2026-03-01T10:00:00.000Z',
          'tags': List<String>.generate(
            10,
            (i) => 'tag$i-abcdefghijklmnopqrstuvwxyz',
          ),
        },
      );
      expect(r.title.length, Resistance.maxTitleLength);
      expect(r.description.length, Resistance.maxDescriptionLength);
      expect(r.tags.length, Resistance.maxTagsCount);
      expect(r.tags.every((t) => t.length <= Resistance.maxTagLength), isTrue);
    });

    test('titre vide -> Sans titre', () {
      final r = Resistance.fromMap(
        id: 'r3',
        map: <String, Object?>{
          'title': '   ',
          'createdAtUtc': '2026-03-01T10:00:00.000Z',
        },
      );
      expect(r.title, 'Sans titre');
    });

    test('bestStreakDays négatif dans la map -> 0', () {
      final r = Resistance.fromMap(
        id: 'r4',
        map: <String, Object?>{
          'title': 'T',
          'createdAtUtc': '2026-03-01T10:00:00.000Z',
          'bestStreakDays': -5,
        },
      );
      expect(r.bestStreakDays, 0);
    });

    test('createdAtUtc accepte un objet avec toDate (compat Timestamp)', () {
      final created = DateTime.utc(2026, 3, 26, 12);
      final r = Resistance.fromMap(
        id: 'r5',
        map: <String, Object?>{
          'title': 'T',
          'createdAtUtc': _FakeTimestamp(created),
        },
      );
      expect(r.createdAtUtc, created);
    });
  });
}
