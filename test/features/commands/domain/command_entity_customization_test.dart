import 'package:flutter_test/flutter_test.dart';
import 'package:rituel/features/commands/domain/entities/command.dart';

void main() {
  group('Command personnalisable rétrocompatible', () {
    test('utilise des valeurs par défaut si champs absents', () {
      final command = Command.fromMap(
        id: 'c1',
        map: <String, Object?>{
          'title': 'Lire',
          'target': 3,
          'progress': 1,
          'frequency': 'daily',
        },
      );

      expect(command.emoji, Command.defaultEmoji);
      expect(command.accentColorValue, isNull);
      expect(command.position, 0);
      expect(command.tags, isEmpty);
      expect(command.activeWeekdays, isEmpty);
    });

    test('désérialise emoji, couleur, position et tags', () {
      final command = Command.fromMap(
        id: 'c2',
        map: <String, Object?>{
          'title': 'Sport',
          'target': 5,
          'progress': 2,
          'frequency': 'weekly',
          'emoji': '💪',
          'accentColorValue': 4280391411,
          'position': 7,
          'tags': <Object?>['santé', 'routine'],
          'activeWeekdays': <Object?>[1, 2, 3, 4, 5],
        },
      );

      expect(command.emoji, '💪');
      expect(command.accentColorValue, 4280391411);
      expect(command.position, 7);
      expect(command.tags, <String>['santé', 'routine']);
      expect(command.activeWeekdays, <int>[1, 2, 3, 4, 5]);
    });

    test('toMap inclut les champs de personnalisation', () {
      final command = Command(
        id: 'c3',
        title: 'Projet',
        target: 10,
        progress: 3,
        frequency: Frequency.monthly,
        emoji: '🚀',
        accentColorValue: 4278190335,
        position: 4,
        tags: const <String>['pro', 'focus'],
        activeWeekdays: const <int>[1, 2, 3, 4, 5],
      );

      final map = command.toMap();

      expect(map['emoji'], '🚀');
      expect(map['accentColorValue'], 4278190335);
      expect(map['position'], 4);
      expect(map['tags'], <String>['pro', 'focus']);
      expect(map['activeWeekdays'], <int>[1, 2, 3, 4, 5]);
    });
  });
}
