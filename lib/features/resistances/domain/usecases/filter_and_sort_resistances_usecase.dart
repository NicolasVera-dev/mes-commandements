import '../entities/resistance.dart';
import 'compute_resistance_streak_usecase.dart';

enum ResistanceSort {
  /// Ordre manuel (position Firestore), puis titre.
  alpha,

  /// Série actuelle décroissante.
  streakHigh,

  /// Série actuelle croissante.
  streakLow,
}

class FilterAndSortResistancesUseCase {
  final ComputeResistanceStreakUseCase _streakUseCase;

  const FilterAndSortResistancesUseCase([
    ComputeResistanceStreakUseCase? streakUseCase,
  ]) : _streakUseCase = streakUseCase ?? const ComputeResistanceStreakUseCase();

  List<Resistance> execute({
    required List<Resistance> resistances,
    required Set<String> tags,
    required ResistanceSort sort,
    required String searchQuery,
    required DateTime nowUtc,
  }) {
    final q = searchQuery.trim().toLowerCase();

    final filtered = resistances.where((r) {
      if (tags.isNotEmpty && !r.tags.any(tags.contains)) return false;
      if (q.isEmpty) return true;
      final inTitle = r.title.toLowerCase().contains(q);
      final inDesc = r.description.toLowerCase().contains(q);
      return inTitle || inDesc;
    }).toList(growable: false);

    int streakOf(Resistance r) =>
        _streakUseCase.execute(resistance: r, nowUtc: nowUtc);

    filtered.sort((a, b) {
      final aAlpha = a.title.toLowerCase();
      final bAlpha = b.title.toLowerCase();
      switch (sort) {
        case ResistanceSort.alpha:
          return (a.position == b.position)
              ? aAlpha.compareTo(bAlpha)
              : a.position.compareTo(b.position);
        case ResistanceSort.streakHigh:
          final sa = streakOf(a);
          final sb = streakOf(b);
          return (sa == sb)
              ? aAlpha.compareTo(bAlpha)
              : sb.compareTo(sa);
        case ResistanceSort.streakLow:
          final sa = streakOf(a);
          final sb = streakOf(b);
          return (sa == sb)
              ? aAlpha.compareTo(bAlpha)
              : sa.compareTo(sb);
      }
    });

    return filtered;
  }
}
