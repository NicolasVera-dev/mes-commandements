import 'package:meta/meta.dart';

/// Domain model representing a command/progress item.
@immutable
class Command {
  static const int maxDescriptionLength = 150;

  final String id;
  final String title;
  final String description;
  final int target;
  final int progress;
  final Frequency frequency;

  const Command({
    required this.id,
    required this.title,
    this.description = '',
    required this.target,
    required this.progress,
    required this.frequency,
  }) : assert(
          description.length <= maxDescriptionLength,
          'La description ne doit pas dépasser $maxDescriptionLength caractères.',
        );

  /// `true` si la progression a atteint (ou dépassé) la cible.
  bool isCompleted() => progress >= target;

  /// `true` si la commande a commencé (progress > 0).
  bool isStarted() => progress > 0;

  Command copyWith({
    String? id,
    String? title,
    String? description,
    int? target,
    int? progress,
    Frequency? frequency,
  }) {
    return Command(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
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
        other.description == description &&
        other.target == target &&
        other.progress == progress &&
        other.frequency == frequency;
  }

  @override
  int get hashCode =>
      Object.hash(id, title, description, target, progress, frequency);

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'title': title,
      'description': description,
      'target': target,
      'progress': progress,
      'frequency': frequency.name,
    };
  }

  factory Command.fromMap({
    required String id,
    required Map<String, Object?> map,
  }) {
    final rawFrequency = map['frequency'];
    final frequencyName = rawFrequency is String ? rawFrequency : null;

    final frequency = frequencyName == null
        ? Frequency.daily
        : Frequency.values.firstWhere(
            (f) => f.name == frequencyName,
            orElse: () => Frequency.daily,
          );

    final description = (map['description'] ?? '').toString();
    final clampedDescription = description.length > maxDescriptionLength
        ? description.substring(0, maxDescriptionLength)
        : description;

    final rawTarget = map['target'];
    final target = rawTarget is num
        ? rawTarget.toInt()
        : int.tryParse((rawTarget ?? '').toString()) ?? 0;
    final rawProgress = map['progress'];
    final progress = rawProgress is num
        ? rawProgress.toInt()
        : int.tryParse((rawProgress ?? '').toString()) ?? 0;

    return Command(
      id: id,
      title: (map['title'] ?? '').toString(),
      description: clampedDescription,
      target: target,
      progress: progress,
      frequency: frequency,
    );
  }
}

enum Frequency { daily, weekly, monthly, yearly }

