import 'package:meta/meta.dart';
import '../services/cycle_key_generator.dart';
import 'command_event.dart';

/// Domain model representing a command/progress item.
@immutable
class Command {
  static const int maxTitleLength = 60;
  static const int maxDescriptionLength = 250;
  static const String defaultEmoji = '🎯';
  static const int maxTagsCount = 5;
  static const int maxTagLength = 20;
  static const List<int> allWeekdays = <int>[
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
    DateTime.sunday,
  ];

  final String id;
  final String title;
  final String description;
  final int target;
  final int progress;
  final Frequency frequency;
  final DateTime? lastResetAt;
  final DateTime? createdAt;
  final String emoji;
  final int? accentColorValue;
  final int position;
  final List<String> tags;
  final List<int> activeWeekdays;

  Command({
    required this.id,
    required this.title,
    this.description = '',
    required this.target,
    required this.progress,
    required this.frequency,
    this.lastResetAt,
    this.createdAt,
    this.emoji = defaultEmoji,
    this.accentColorValue,
    this.position = 0,
    this.tags = const <String>[],
    this.activeWeekdays = const <int>[],
  }) : assert(title.trim().isNotEmpty, 'Le titre ne doit pas être vide.'),
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
       ),
       assert(
         activeWeekdays.every(
           (d) => d >= DateTime.monday && d <= DateTime.sunday,
         ),
         'Les jours actifs doivent être compris entre 1 (lundi) et 7 (dimanche).',
       ),
       assert(
         activeWeekdays.toSet().length == activeWeekdays.length,
         'Les jours actifs ne doivent pas contenir de doublons.',
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
    DateTime? createdAt,
    String? emoji,
    int? accentColorValue,
    int? position,
    List<String>? tags,
    List<int>? activeWeekdays,
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
      lastResetAt: clearLastResetAt ? null : (lastResetAt ?? this.lastResetAt),
      createdAt: createdAt ?? this.createdAt,
      emoji: emoji ?? this.emoji,
      accentColorValue: clearAccentColorValue
          ? null
          : (accentColorValue ?? this.accentColorValue),
      position: position ?? this.position,
      tags: tags ?? this.tags,
      activeWeekdays: activeWeekdays ?? this.activeWeekdays,
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

  /// Génère un cycleKey déterministe en fonction de la fréquence.
  String cycleKeyAt(DateTime atUtc) {
    return CycleKeyGenerator.forFrequency(
      frequency: frequency,
      atUtc: atUtc.toUtc(),
    );
  }

  bool isActiveOnDayUtc(DateTime dayUtc) {
    if (frequency != Frequency.daily) return true;
    if (activeWeekdays.isEmpty) return true;
    final weekday = dayUtc.toUtc().weekday;
    return activeWeekdays.contains(weekday);
  }

  /// Construit un événement domain à partir de l'état courant.
  CommandEvent toEvent({
    required CommandEventType type,
    required DateTime actionAtUtc,
  }) {
    return CommandEvent.fromCommandSnapshot(
      type: type,
      command: this,
      actionAtUtc: actionAtUtc.toUtc(),
    );
  }

  DateTime _periodStart(DateTime nowUtc) {
    return CycleKeyGenerator.cycleStartUtc(frequency, nowUtc);
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
        other.createdAt == createdAt &&
        other.emoji == emoji &&
        other.accentColorValue == accentColorValue &&
        other.position == position &&
        _listEquals(other.tags, tags) &&
        _listEquals(other.activeWeekdays, activeWeekdays);
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    target,
    progress,
    frequency,
    lastResetAt,
    createdAt,
    emoji,
    accentColorValue,
    position,
    Object.hashAll(tags),
    Object.hashAll(activeWeekdays),
  );

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'title': title,
      'description': description,
      'target': target,
      'progress': progress,
      'frequency': frequency.name,
      'lastResetAt': lastResetAt?.toUtc().toIso8601String(),
      'createdAt': createdAt?.toUtc().toIso8601String(),
      'emoji': emoji,
      'accentColorValue': accentColorValue,
      'position': position,
      'tags': tags,
      'activeWeekdays': activeWeekdays,
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
    final createdAt = _parseDateTime(map['createdAt']);
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
              .map(
                (t) =>
                    t.length > maxTagLength ? t.substring(0, maxTagLength) : t,
              )
              .toList(growable: false)
        : const <String>[];
    final activeWeekdays = _parseActiveWeekdays(map['activeWeekdays']);
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
      createdAt: createdAt,
      emoji: emoji,
      accentColorValue: accentColorValue,
      position: position,
      tags: tags,
      activeWeekdays: activeWeekdays,
    );
  }

  static DateTime? _parseDateTime(Object? raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw.toUtc();
    try {
      final dynamicValue = raw as dynamic;
      final timestampDate = dynamicValue.toDate();
      if (timestampDate is DateTime) return timestampDate.toUtc();
    } catch (_) {
      // Ignorer et tenter un parsing string juste après.
    }
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

  static List<int> _parseActiveWeekdays(Object? raw) {
    if (raw is! List) return const <int>[];
    final parsed =
        raw
            .map((e) {
              if (e is num) return e.toInt();
              return int.tryParse(e.toString());
            })
            .whereType<int>()
            .where((d) => d >= DateTime.monday && d <= DateTime.sunday)
            .toSet()
            .toList(growable: false)
          ..sort();
    if (parsed.length == allWeekdays.length) {
      return const <int>[];
    }
    return parsed;
  }
}

enum Frequency { daily, weekly, monthly, yearly }
