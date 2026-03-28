import 'package:flutter_test/flutter_test.dart';
import 'package:mes_commandements/features/commands/domain/entities/command.dart';
import 'package:mes_commandements/features/commands/domain/usecases/filter_and_sort_commands_usecase.dart';

void main() {
  group('FilterAndSortCommandsUseCase', () {
    const useCase = FilterAndSortCommandsUseCase();

    Command make({
      required String id,
      required String title,
      Frequency frequency = Frequency.daily,
      int target = 5,
      int progress = 0,
      int position = 0,
      List<String> tags = const [],
    }) {
      return Command(
        id: id,
        title: title,
        target: target,
        progress: progress,
        frequency: frequency,
        position: position,
        tags: tags,
      );
    }

    List<Command> run({
      required List<Command> commands,
      Set<Frequency>? frequencies,
      Set<CommandStatusFilter> statuses = const {},
      Set<String> tags = const {},
      CommandSort sort = CommandSort.alpha,
      String searchQuery = '',
    }) {
      return useCase.execute(
        commands: commands,
        frequencies: frequencies,
        statuses: statuses,
        tags: tags,
        sort: sort,
        searchQuery: searchQuery,
      );
    }

    test('entrée vide retourne liste vide', () {
      expect(
        run(commands: []),
        isEmpty,
      );
    });

    test('un seul élément est renvoyé tel quel (tri alpha par position)', () {
      final only = make(id: 'a', title: 'Seul', position: 0);
      expect(run(commands: [only]), [only]);
    });

    test('filtre fréquence daily ne garde que daily', () {
      final commands = [
        make(id: 'd', title: 'D', frequency: Frequency.daily),
        make(id: 'w', title: 'W', frequency: Frequency.weekly),
        make(id: 'm', title: 'M', frequency: Frequency.monthly),
        make(id: 'y', title: 'Y', frequency: Frequency.yearly),
      ];
      final result = run(commands: commands, frequencies: {Frequency.daily});
      expect(result.map((c) => c.id), ['d']);
    });

    test('filtre fréquence weekly ne garde que weekly', () {
      final commands = [
        make(id: 'd', title: 'D', frequency: Frequency.daily),
        make(id: 'w', title: 'W', frequency: Frequency.weekly),
      ];
      expect(
        run(commands: commands, frequencies: {Frequency.weekly}).map((c) => c.id),
        ['w'],
      );
    });

    test('filtre fréquence monthly ne garde que monthly', () {
      final commands = [
        make(id: 'm', title: 'M', frequency: Frequency.monthly),
        make(id: 'y', title: 'Y', frequency: Frequency.yearly),
      ];
      expect(
        run(commands: commands, frequencies: {Frequency.monthly}).map((c) => c.id),
        ['m'],
      );
    });

    test('filtre fréquence yearly ne garde que yearly', () {
      final commands = [
        make(id: 'y', title: 'Y', frequency: Frequency.yearly),
        make(id: 'd', title: 'D', frequency: Frequency.daily),
      ];
      expect(
        run(commands: commands, frequencies: {Frequency.yearly}).map((c) => c.id),
        ['y'],
      );
    });

    test('progress == 0 → statut notStarted', () {
      final c = make(id: '1', title: 'A', progress: 0, target: 5);
      final result = run(
        commands: [c],
        statuses: {CommandStatusFilter.notStarted},
      );
      expect(result, [c]);
    });

    test('progress == target - 1 → statut started', () {
      final c = make(id: '1', title: 'A', progress: 4, target: 5);
      final result = run(
        commands: [c],
        statuses: {CommandStatusFilter.started},
      );
      expect(result, [c]);
    });

    test('progress == target → statut completed', () {
      final c = make(id: '1', title: 'A', progress: 5, target: 5);
      final result = run(
        commands: [c],
        statuses: {CommandStatusFilter.completed},
      );
      expect(result, [c]);
    });

    test('progress > target → toujours completed', () {
      final c = make(id: '1', title: 'A', progress: 10, target: 5);
      expect(c.isCompleted(), isTrue);
      final result = run(
        commands: [c],
        statuses: {CommandStatusFilter.completed},
      );
      expect(result, [c]);
    });

    test('combinaison fréquence daily + statut completed + tag + recherche', () {
      final commands = [
        make(
          id: '1',
          title: 'Sport matin',
          frequency: Frequency.daily,
          progress: 3,
          target: 3,
          tags: const ['sante'],
        ),
        make(
          id: '2',
          title: 'Sport soir',
          frequency: Frequency.daily,
          progress: 1,
          target: 3,
          tags: const ['sante'],
        ),
        make(
          id: '3',
          title: 'Sport',
          frequency: Frequency.weekly,
          progress: 3,
          target: 3,
          tags: const ['sante'],
        ),
      ];
      final result = run(
        commands: commands,
        frequencies: {Frequency.daily},
        statuses: {CommandStatusFilter.completed},
        tags: {'sante'},
        searchQuery: 'matin',
      );
      expect(result.map((c) => c.id), ['1']);
    });

    test('combinaison fréquence + statut + plusieurs tags (any)', () {
      final commands = [
        make(
          id: 'a',
          title: 'A',
          frequency: Frequency.monthly,
          progress: 0,
          target: 2,
          tags: const ['x'],
        ),
        make(
          id: 'b',
          title: 'B',
          frequency: Frequency.monthly,
          progress: 2,
          target: 2,
          tags: const ['y'],
        ),
      ];
      final result = run(
        commands: commands,
        frequencies: {Frequency.monthly},
        statuses: {CommandStatusFilter.completed},
        tags: {'x', 'y'},
      );
      expect(result.map((c) => c.id), ['b']);
    });

    test('recherche trim et insensible à la casse', () {
      final commands = [
        make(id: '1', title: 'Rituel Zen'),
      ];
      expect(
        run(commands: commands, searchQuery: '  ZEN ').map((c) => c.id),
        ['1'],
      );
    });

    test('frequencies null ne filtre pas par fréquence', () {
      final commands = [
        make(id: 'd', title: 'D', frequency: Frequency.daily),
        make(id: 'w', title: 'W', frequency: Frequency.weekly),
      ];
      expect(run(commands: commands, frequencies: null).length, 2);
    });

    test('statuses vide ne filtre pas par statut', () {
      final commands = [
        make(id: '1', title: 'A', progress: 0, target: 5),
        make(id: '2', title: 'B', progress: 5, target: 5),
      ];
      expect(run(commands: commands, statuses: {}).length, 2);
    });

    test('tags vide ne filtre pas par tag', () {
      final commands = [
        make(id: '1', title: 'A', tags: const ['t']),
      ];
      expect(run(commands: commands, tags: {}).length, 1);
    });
  });
}
