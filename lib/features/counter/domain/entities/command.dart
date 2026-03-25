import 'package:meta/meta.dart';

/// Domain model representing a command/progress item.
@immutable
class Command {
  final String id;
  final String title;
  final int target;
  final int progress;
  final Frequency frequency;

  const Command({
    required this.id,
    required this.title,
    required this.target,
    required this.progress,
    required this.frequency,
  });

  /// `true` si la progression a atteint (ou dépassé) la cible.
  bool isCompleted() => progress >= target;

  /// `true` si la commande a commencé (progress > 0).
  bool isStarted() => progress > 0;

  Command copyWith({
    String? id,
    String? title,
    int? target,
    int? progress,
    Frequency? frequency,
  }) {
    return Command(
      id: id ?? this.id,
      title: title ?? this.title,
      target: target ?? this.target,
      progress: progress ?? this.progress,
      frequency: frequency ?? this.frequency,
    );
  }

  /// Incrémente `progress` jusqu'à `target` (reste bloqué à `target`).
  Command incrementProgress() {
    final next = progress < target ? progress + 1 : progress;
    return copyWith(progress: next);
  }

  /// Remet la progression à 0.
  Command resetProgress() => copyWith(progress: 0);

  @override
  bool operator ==(Object other) {
    return other is Command &&
        other.id == id &&
        other.title == title &&
        other.target == target &&
        other.progress == progress &&
        other.frequency == frequency;
  }

  @override
  int get hashCode => Object.hash(id, title, target, progress, frequency);
}

enum Frequency { daily, weekly, monthly, yearly }

