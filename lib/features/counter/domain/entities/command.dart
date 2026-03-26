import 'package:meta/meta.dart';

/// Domain model representing a command/progress item.
@immutable
class Command {
  static const int maxTitleLength = 60;
  static const int maxDescriptionLength = 150;
  static const String defaultEmoji = '🎯';
  static const int maxTagsCount = 5;
  static const int maxTagLength = 20;

  final String id;
  final String title;
  final String description;
  final int target;
  final int progress;
  final Frequency frequency;
  final DateTime? lastResetAt;
  final String emoji;
  final int? accentColorValue;
  final int position;
  final List<String> tags;

  Command({
    required this.id,
    required this.title,
    this.description = '',
    required this.target,
    required this.progress,
    required this.frequency,
    this.lastResetAt,
    this.emoji = defaultEmoji,
    this.accentColorValue,
    this.position = 0,
    this.tags = const <String>[],
  }) : assert(
          title.trim().isNotEmpty,
          'Le titre ne doit pas être vide.',
        ),
        assert(
          title.trim().length <= maxTitleLength,
          'Le titre ne doit pas dépasser $maxTitleLength caractères.',
        ),
        assert(
          description.length <= maxDescriptionLength,
          'La description ne doit pas dépasser $maxDescriptionLength caractères.',
        ),
        assert(
          tags.length <= maxTagsCount,
          'Le nombre de tags ne doit pas dépasser $maxTagsCount.',
        ),
        assert(
          tags.every((t) => t.trim().length <= maxTagLength),
          'Chaque tag ne doit pas dépasser $maxTagLength caractères.',
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
    DateTime? lastResetAt,
    String? emoji,
    int? accentColorValue,
    int? position,
    List<String>? tags,
    bool clearLastResetAt = false,
    bool clearAccentColorValue = false,
  }) {
    return Command(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      target: target ?? this.target,
      progress: progress ?? this.progress,
      frequency: frequency ?? this.frequency,
      lastResetAt: clearLastResetAt
          ? null
          : (lastResetAt ?? this.lastResetAt),
      emoji: emoji ?? this.emoji,
      accentColorValue: clearAccentColorValue
          ? null
          : (accentColorValue ?? this.accentColorValue),
      position: position ?? this.position,
      tags: tags ?? this.tags,
    );
  }

  /// Incrémente `progress` jusqu'à `target` (reste bloqué à `target`).
  Command incrementProgress() {
    final next = progress < target ? progress + 1 : progress;
    return copyWith(progress: next);
  }

  /// Remet la progression à 0.
  Command resetProgress({DateTime? resetAt}) {
    final normalizedResetAt = (resetAt ?? DateTime.now()).toUtc();
    return copyWith(progress: 0, lastResetAt: normalizedResetAt);
  }

  /// Détermine si la progression doit être réinitialisée pour la période en cours.
  bool shouldAutoReset(DateTime now) {
    final currentBoundary = _periodStart(now.toUtc());
    final effectiveLastReset = lastResetAt?.toUtc();
    if (effectiveLastReset == null) return true;
    return effectiveLastReset.isBefore(currentBoundary);
  }

  /// Applique un reset automatique si nécessaire, sinon retourne l'instance.
  Command applyAutoResetIfNeeded(DateTime now) {
    if (!shouldAutoReset(now)) return this;
    return resetProgress(resetAt: now.toUtc());
  }

  DateTime _periodStart(DateTime nowUtc) {
    switch (frequency) {
      case Frequency.daily:
        return DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);
      case Frequency.weekly:
        final deltaFromMonday = nowUtc.weekday - DateTime.monday;
        final monday = nowUtc.subtract(Duration(days: deltaFromMonday));
        return DateTime.utc(monday.year, monday.month, monday.day);
      case Frequency.monthly:
        return DateTime.utc(nowUtc.year, nowUtc.month, 1);
      case Frequency.yearly:
        return DateTime.utc(nowUtc.year, 1, 1);
    }
  }

  @override
  bool operator ==(Object other) {
    return other is Command &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.target == target &&
        other.progress == progress &&
        other.frequency == frequency &&
        other.lastResetAt == lastResetAt &&
        other.emoji == emoji &&
        other.accentColorValue == accentColorValue &&
        other.position == position &&
        _listEquals(other.tags, tags);
  }

  @override
  int get hashCode =>
      Object.hash(
        id,
        title,
        description,
        target,
        progress,
        frequency,
        lastResetAt,
        emoji,
        accentColorValue,
        position,
        Object.hashAll(tags),
      );

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'title': title,
      'description': description,
      'target': target,
      'progress': progress,
      'frequency': frequency.name,
      'lastResetAt': lastResetAt?.toUtc().toIso8601String(),
      'emoji': emoji,
      'accentColorValue': accentColorValue,
      'position': position,
      'tags': tags,
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
    final rawTitle = (map['title'] ?? '').toString().trim();
    final title = rawTitle.length > maxTitleLength
        ? rawTitle.substring(0, maxTitleLength)
        : rawTitle;

    final rawTarget = map['target'];
    final target = rawTarget is num
        ? rawTarget.toInt()
        : int.tryParse((rawTarget ?? '').toString()) ?? 0;
    final rawProgress = map['progress'];
    final progress = rawProgress is num
        ? rawProgress.toInt()
        : int.tryParse((rawProgress ?? '').toString()) ?? 0;
    final lastResetAt = _parseDateTime(map['lastResetAt']);
    final rawAccentColor = map['accentColorValue'];
    final accentColorValue = rawAccentColor is num
        ? rawAccentColor.toInt()
        : int.tryParse((rawAccentColor ?? '').toString());
    final rawPosition = map['position'];
    final position = rawPosition is num
        ? rawPosition.toInt()
        : int.tryParse((rawPosition ?? '').toString()) ?? 0;
    final rawTags = map['tags'];
    final tags = rawTags is List
        ? rawTags
            .map((e) => e.toString().trim())
            .where((t) => t.isNotEmpty)
            .take(maxTagsCount)
            .map((t) => t.length > maxTagLength ? t.substring(0, maxTagLength) : t)
            .toList(growable: false)
        : const <String>[];
    final rawEmoji = (map['emoji'] ?? '').toString().trim();
    final emoji = rawEmoji.isEmpty ? defaultEmoji : rawEmoji;

    return Command(
      id: id,
      title: title,
      description: clampedDescription,
      target: target,
      progress: progress,
      frequency: frequency,
      lastResetAt: lastResetAt,
      emoji: emoji,
      accentColorValue: accentColorValue,
      position: position,
      tags: tags,
    );
  }

  static DateTime? _parseDateTime(Object? raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw.toUtc();
    final parsed = DateTime.tryParse(raw.toString());
    return parsed?.toUtc();
  }

  static bool _listEquals(List<Object?> a, List<Object?> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

enum Frequency { daily, weekly, monthly, yearly }

