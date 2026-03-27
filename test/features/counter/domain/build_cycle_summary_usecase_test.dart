import 'package:flutter_test/flutter_test.dart';
import 'package:mes_commandements/features/counter/domain/entities/command.dart';
import 'package:mes_commandements/features/counter/domain/entities/command_event.dart';
import 'package:mes_commandements/features/counter/domain/usecases/build_cycle_summary_usecase.dart';

void main() {
  group('BuildCycleSummaryUseCase', () {
    const useCase = BuildCycleSummaryUseCase();

    CommandEvent event({
      required CommandEventType type,
      required String cycleKey,
    }) {
      return CommandEvent(
        type: type,
        actionAtUtc: DateTime.utc(2026, 3, 1),
        progressAfterAction: 1,
        targetAtAction: 3,
        cycleKey: cycleKey,
      );
    }

    group('daily', () {
      test('compte succès, échecs et exclut les cycles cachés avant createdAt', () {
        final grouped = <String, List<CommandEvent>>{
          '2026-03-12': [event(type: CommandEventType.complete, cycleKey: '2026-03-12')],
          '2026-03-13': [event(type: CommandEventType.increment, cycleKey: '2026-03-13')],
        };

        final summary = useCase.execute(
          frequency: Frequency.daily,
          anchorUtc: DateTime.utc(2026, 3, 1),
          grouped: grouped,
          currentKey: '2026-03-15',
          createdAtUtc: DateTime.utc(2026, 3, 10),
          nowUtc: DateTime.utc(2026, 3, 15, 12),
        );

        expect(summary.success, 1);
        // Du 10 au 14: 5 cycles visibles passés, 1 succès, donc 4 échecs.
        expect(summary.failed, 4);
        expect(summary.completionRate, 20);
      });
    });

    group('weekly', () {
      test('considère un cycle courant complété comme succès', () {
        final grouped = <String, List<CommandEvent>>{
          '2026-S13': [event(type: CommandEventType.complete, cycleKey: '2026-S13')],
        };

        final summary = useCase.execute(
          frequency: Frequency.weekly,
          anchorUtc: DateTime.utc(2026, 3, 1),
          grouped: grouped,
          currentKey: '2026-S13',
          createdAtUtc: DateTime.utc(2026, 2, 1),
          nowUtc: DateTime.utc(2026, 3, 26, 12),
        );

        expect(summary.success, 1);
        expect(summary.failed, greaterThanOrEqualTo(0));
      });
    });
  });
}
