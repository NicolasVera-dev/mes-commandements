import 'package:meta/meta.dart';

/// Habitude à abandonner (inverse d’un commandement).
@immutable
class Resistance {
  static const int maxTitleLength = 60;
  static const int maxDescriptionLength = 150;
  static const String defaultEmoji = '🛡️';
  static const int maxTagsCount = 5;
  static const int maxTagLength = 20;

  final String id;
  final String title;
  final String description;
  final DateTime createdAtUtc;
  final String emoji;
  final int? accentColorValue;
  final int position;
  final List<String> tags;
  /// Dernière rechute enregistrée ; `null` si aucune.
  final DateTime? lastRelapseAtUtc;
  /// Meilleur streak (jours) jamais atteint avant une rechute.
  final int bestStreakDays;

  Resistance({
    required this.id,
    required this.title,
    this.description = '',
    required this.createdAtUtc,
    this.emoji = defaultEmoji,
    this.accentColorValue,
    this.position = 0,
    this.tags = const <String>[],
    this.lastRelapseAtUtc,
    this.bestStreakDays = 0,
  })  : assert(title.trim().isNotEmpty, 'Le titre ne doit pas être vide.'),
        assert(title.trim().length <= maxTitleLength),
        assert(description.length <= maxDescriptionLength),
        assert(tags.length <= maxTagsCount),
        assert(tags.every((t) => t.trim().length <= maxTagLength)),
        assert(bestStreakDays >= 0);

  Resistance copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAtUtc,
    String? emoji,
    int? accentColorValue,
    int? position,
    List<String>? tags,
    DateTime? lastRelapseAtUtc,
    bool clearLastRelapseAtUtc = false,
    bool clearAccentColorValue = false,
    int? bestStreakDays,
  }) {
    return Resistance(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      emoji: emoji ?? this.emoji,
      accentColorValue: clearAccentColorValue
          ? null
          : (accentColorValue ?? this.accentColorValue),
      position: position ?? this.position,
      tags: tags ?? this.tags,
      lastRelapseAtUtc: clearLastRelapseAtUtc
          ? null
          : (lastRelapseAtUtc ?? this.lastRelapseAtUtc),
      bestStreakDays: bestStreakDays ?? this.bestStreakDays,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'title': title,
      'description': description,
      'createdAtUtc': createdAtUtc.toUtc().toIso8601String(),
      'emoji': emoji,
      'accentColorValue': accentColorValue,
      'position': position,
      'tags': tags,
      'lastRelapseAtUtc': lastRelapseAtUtc?.toUtc().toIso8601String(),
      'bestStreakDays': bestStreakDays,
    };
  }

  factory Resistance.fromMap({
    required String id,
    required Map<String, Object?> map,
  }) {
    final description = (map['description'] ?? '').toString();
    final clampedDescription = description.length > maxDescriptionLength
        ? description.substring(0, maxDescriptionLength)
        : description;
    final rawTitle = (map['title'] ?? '').toString().trim();
    final title = rawTitle.length > maxTitleLength
        ? rawTitle.substring(0, maxTitleLength)
        : rawTitle;
    final createdAtUtc = _parseDateTime(map['createdAtUtc']) ?? DateTime.utc(1970, 1, 1);
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
    final lastRelapseAtUtc = _parseDateTime(map['lastRelapseAtUtc']);
    final rawBest = map['bestStreakDays'];
    final bestStreakDays = rawBest is num
        ? rawBest.toInt()
        : int.tryParse((rawBest ?? '0').toString()) ?? 0;

    return Resistance(
      id: id,
      title: title.isEmpty ? 'Sans titre' : title,
      description: clampedDescription,
      createdAtUtc: createdAtUtc,
      emoji: emoji,
      accentColorValue: accentColorValue,
      position: position,
      tags: tags,
      lastRelapseAtUtc: lastRelapseAtUtc,
      bestStreakDays: bestStreakDays < 0 ? 0 : bestStreakDays,
    );
  }

  static DateTime? _parseDateTime(Object? raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw.toUtc();
    try {
      final dynamicValue = raw as dynamic;
      final timestampDate = dynamicValue.toDate();
      if (timestampDate is DateTime) return timestampDate.toUtc();
    } catch (_) {}
    final parsed = DateTime.tryParse(raw.toString());
    return parsed?.toUtc();
  }
}
