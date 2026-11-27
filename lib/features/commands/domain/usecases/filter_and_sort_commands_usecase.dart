import '../entities/command.dart';

enum CommandStatusFilter { all, notStarted, started, completed, paused }

enum CommandSort {
  alpha,
  completedFirst,
  notCompletedFirst,
  highestProgressFirst,
  lowestProgressFirst,
}

class FilterAndSortCommandsUseCase {
  const FilterAndSortCommandsUseCase();

  List<Command> execute({
    required List<Command> commands,
    required Set<Frequency>? frequencies,
    required Set<CommandStatusFilter> statuses,
    required Set<String> tags,
    required CommandSort sort,
    required String searchQuery,
    bool hiddenOnly = false,
    DateTime? now,
  }) {
    final q = searchQuery.trim().toLowerCase();
    final instant = now ?? DateTime.now().toUtc();

    final filtered = commands
        .where((c) => c.isHidden == hiddenOnly)
        .where(
          (c) => frequencies == null ? true : frequencies.contains(c.frequency),
        )
        .where(
          (c) =>
              statuses.isEmpty ||
              statuses.contains(CommandStatusFilter.all) ||
              statuses.contains(_statusOf(c, instant)),
        )
        .where((c) => tags.isEmpty ? true : c.tags.any(tags.contains))
        .where((c) => q.isEmpty ? true : c.title.toLowerCase().contains(q))
        .toList(growable: false);

    double ratio(Command c) => c.target <= 0 ? 0.0 : c.progress / c.target;

    filtered.sort((a, b) {
      final aAlpha = a.title.toLowerCase();
      final bAlpha = b.title.toLowerCase();
      switch (sort) {
        case CommandSort.alpha:
          return (a.position == b.position)
              ? aAlpha.compareTo(bAlpha)
              : a.position.compareTo(b.position);
        case CommandSort.completedFirst:
          return (a.isCompleted() == b.isCompleted())
              ? aAlpha.compareTo(bAlpha)
              : (a.isCompleted() ? -1 : 1);
        case CommandSort.notCompletedFirst:
          return (a.isCompleted() == b.isCompleted())
              ? aAlpha.compareTo(bAlpha)
              : (a.isCompleted() ? 1 : -1);
        case CommandSort.highestProgressFirst:
          final aR = ratio(a);
          final bR = ratio(b);
          return (aR == bR) ? aAlpha.compareTo(bAlpha) : bR.compareTo(aR);
        case CommandSort.lowestProgressFirst:
          final aR = ratio(a);
          final bR = ratio(b);
          return (aR == bR) ? aAlpha.compareTo(bAlpha) : aR.compareTo(bR);
      }
    });

    return filtered;
  }

  CommandStatusFilter _statusOf(Command command, DateTime now) {
    if (command.isHidden || command.isPausedAt(now)) {
      return CommandStatusFilter.paused;
    }
    if (command.isCompleted()) return CommandStatusFilter.completed;
    if (command.isStarted()) return CommandStatusFilter.started;
    return CommandStatusFilter.notStarted;
  }
}
