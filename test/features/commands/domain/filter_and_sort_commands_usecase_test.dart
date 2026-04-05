import 'package:flutter_test/flutter_test.dart';
import 'package:rituel/features/commands/domain/entities/command.dart';
import 'package:rituel/features/commands/domain/usecases/filter_and_sort_commands_usecase.dart';

void main() {
  group('FilterAndSortCommandsUseCase', () {
    const useCase = FilterAndSortCommandsUseCase();

    final c1 = Command(
      id: '1',
      title: 'Alpha',
      target: 10,
      progress: 10,
      frequency: Frequency.daily,
      position: 1,
      tags: const ['sante'],
    );
    final c2 = Command(
      id: '2',
      title: 'Beta',
      target: 10,
      progress: 3,
      frequency: Frequency.weekly,
      position: 0,
      tags: const ['travail'],
    );
    final c3 = Command(
      id: '3',
      title: 'Gamma',
      target: 10,
      progress: 0,
      frequency: Frequency.monthly,
      position: 2,
      tags: const ['sante', 'focus'],
    );

    List<Command> run({
      Set<Frequency>? frequencies,
      Set<CommandStatusFilter> statuses = const {},
      Set<String> tags = const {},
      CommandSort sort = CommandSort.alpha,
      String search = '',
    }) {
      return useCase.execute(
        commands: [c1, c2, c3],
        frequencies: frequencies,
        statuses: statuses,
        tags: tags,
        sort: sort,
        searchQuery: search,
      );
    }

    test('filtre par fréquence', () {
      final result = run(frequencies: {Frequency.weekly});
      expect(result.map((e) => e.id), ['2']);
    });

    test('filtre par statut completed', () {
      final result = run(statuses: {CommandStatusFilter.completed});
      expect(result.map((e) => e.id), ['1']);
    });

    test('filtre par tags (any)', () {
      final result = run(tags: {'focus'});
      expect(result.map((e) => e.id), ['3']);
    });

    test('filtre par recherche case-insensitive', () {
      final result = run(search: 'alp');
      expect(result.map((e) => e.id), ['1']);
    });

    test('tri manuel alpha combine position puis titre', () {
      final result = run(sort: CommandSort.alpha);
      expect(result.map((e) => e.id), ['2', '1', '3']);
    });

    test('tri completedFirst', () {
      final result = run(sort: CommandSort.completedFirst);
      expect(result.first.id, '1');
    });

    test('tri notCompletedFirst', () {
      final result = run(sort: CommandSort.notCompletedFirst);
      expect(result.last.id, '1');
    });

    test('tri highestProgressFirst', () {
      final result = run(sort: CommandSort.highestProgressFirst);
      expect(result.map((e) => e.id), ['1', '2', '3']);
    });

    test('tri lowestProgressFirst', () {
      final result = run(sort: CommandSort.lowestProgressFirst);
      expect(result.map((e) => e.id), ['3', '2', '1']);
    });
  });
}
