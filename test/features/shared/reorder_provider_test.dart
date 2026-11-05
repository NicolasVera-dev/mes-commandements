import 'package:flutter_test/flutter_test.dart';
import 'package:rituel/features/commands/domain/entities/command.dart';
import 'package:rituel/features/commands/domain/entities/command_position_update.dart';
import 'package:rituel/features/commands/domain/repositories/command_repository.dart';
import 'package:rituel/features/commands/presentation/state/command_provider.dart';
import 'package:rituel/features/resistances/domain/entities/resistance.dart';
import 'package:rituel/features/resistances/domain/entities/resistance_position_update.dart';
import 'package:rituel/features/resistances/domain/repositories/resistance_repository.dart';
import 'package:rituel/features/resistances/domain/usecases/record_resistance_relapse_usecase.dart';
import 'package:rituel/features/resistances/presentation/state/resistance_provider.dart';

class _Commands extends Fake implements CommandRepository {
  List<CommandPositionUpdate>? saved;

  @override
  Stream<List<Command>> watchAll() => const Stream.empty();

  @override
  Future<void> updatePositions(List<CommandPositionUpdate> updates) async {
    saved = updates;
  }
}

class _Resistances extends Fake implements ResistanceRepository {
  List<ResistancePositionUpdate>? saved;

  @override
  Stream<List<Resistance>> watchAll() => const Stream.empty();

  @override
  Future<void> updatePositions(List<ResistancePositionUpdate> updates) async {
    saved = updates;
  }
}

void main() {
  // onReorderItem supplies the final insertion index, already adjusted by Flutter.
  for (final scenario in [
    (oldIndex: 0, newIndex: 2, expected: ['b', 'c', 'a']),
    (oldIndex: 2, newIndex: 0, expected: ['c', 'a', 'b']),
    (oldIndex: 0, newIndex: 1, expected: ['b', 'a', 'c']),
  ]) {
    test(
      'commands reorder ${scenario.oldIndex} to ${scenario.newIndex}',
      () async {
        final repository = _Commands();
        final provider = CommandProvider(repository: repository);
        addTearDown(provider.dispose);
        final commands = [
          for (final id in ['a', 'b', 'c'])
            Command(
              id: id,
              title: id,
              target: 1,
              progress: 0,
              frequency: Frequency.daily,
            ),
        ];
        await provider.reorderCommands(
          oldIndex: scenario.oldIndex,
          newIndex: scenario.newIndex,
          visibleCommands: commands,
        );
        expect(
          repository.saved!.map((update) => update.commandId),
          scenario.expected,
        );
        expect(repository.saved!.map((update) => update.position), [0, 1, 2]);
      },
    );

    test(
      'resistances reorder ${scenario.oldIndex} to ${scenario.newIndex}',
      () async {
        final repository = _Resistances();
        final provider = ResistanceProvider(
          repository: repository,
          recordRelapseUseCase: RecordResistanceRelapseUseCase(repository),
        );
        addTearDown(provider.dispose);
        final resistances = [
          for (final id in ['a', 'b', 'c'])
            Resistance(id: id, title: id, createdAtUtc: DateTime.utc(2026)),
        ];
        await provider.reorderResistances(
          oldIndex: scenario.oldIndex,
          newIndex: scenario.newIndex,
          visible: resistances,
        );
        expect(
          repository.saved!.map((update) => update.resistanceId),
          scenario.expected,
        );
        expect(repository.saved!.map((update) => update.position), [0, 1, 2]);
      },
    );
  }
}
