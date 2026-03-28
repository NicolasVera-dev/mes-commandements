import 'package:flutter_test/flutter_test.dart';
import 'package:mes_commandements/features/commands/domain/entities/command.dart';
import 'package:mes_commandements/features/commands/domain/entities/command_event.dart';

class _FakeTimestamp {
  final DateTime value;
  _FakeTimestamp(this.value);
  DateTime toDate() => value;
}

void main() {
  group('Validation modèle Command', () {
    test('échoue si titre vide', () {
      expect(
        () => Command(
          id: 'c1',
          title: '   ',
          target: 1,
          progress: 0,
          frequency: Frequency.daily,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('échoue si description dépasse la limite', () {
      expect(
        () => Command(
          id: 'c1',
          title: 'Titre',
          description: 'a' * (Command.maxDescriptionLength + 1),
          target: 1,
          progress: 0,
          frequency: Frequency.daily,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('échoue si plus de 5 tags', () {
      expect(
        () => Command(
          id: 'c1',
          title: 'Titre',
          target: 1,
          progress: 0,
          frequency: Frequency.daily,
          tags: const ['a', 'b', 'c', 'd', 'e', 'f'],
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('Rétrocompatibilité Command.fromMap', () {
    test('fréquence invalide -> fallback daily', () {
      final command = Command.fromMap(
        id: 'c1',
        map: <String, Object?>{
          'title': 'T',
          'target': 2,
          'progress': 1,
          'frequency': 'invalide',
        },
      );
      expect(command.frequency, Frequency.daily);
    });

    test('title et tags sont clampés aux limites', () {
      final command = Command.fromMap(
        id: 'c2',
        map: <String, Object?>{
          'title': 'x' * 80,
          'target': 2,
          'progress': 1,
          'frequency': 'daily',
          'tags': List<String>.generate(10, (i) => 'tag$i-abcdefghijklmnopqrstuvwxyz'),
        },
      );
      expect(command.title.length, Command.maxTitleLength);
      expect(command.tags.length, Command.maxTagsCount);
      expect(command.tags.every((t) => t.length <= Command.maxTagLength), isTrue);
    });

    test('createdAt accepte un objet avec toDate (compat Timestamp)', () {
      final created = DateTime.utc(2026, 3, 26, 12);
      final command = Command.fromMap(
        id: 'c3',
        map: <String, Object?>{
          'title': 'T',
          'target': 1,
          'progress': 0,
          'frequency': 'daily',
          'createdAt': _FakeTimestamp(created),
        },
      );
      expect(command.createdAt, created);
    });
  });

  group('Validation modèle CommandEvent', () {
    test('conserve les champs obligatoires', () {
      final event = CommandEvent(
        type: CommandEventType.increment,
        actionAtUtc: DateTime.utc(2026, 3, 26, 8),
        progressAfterAction: 2,
        targetAtAction: 4,
        cycleKey: '2026-03-26',
      );
      expect(event.type, CommandEventType.increment);
      expect(event.progressAfterAction, 2);
      expect(event.targetAtAction, 4);
      expect(event.cycleKey, '2026-03-26');
    });
  });
}
