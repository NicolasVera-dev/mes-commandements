import 'package:flutter_test/flutter_test.dart';
import 'package:rituel/features/resistances/domain/entities/resistance.dart';
import 'package:rituel/features/resistances/presentation/widgets/resistance_creation_templates.dart';

void main() {
  final createdAtUtc = DateTime.utc(2026, 1, 1);

  group('kResistanceCreationTemplates', () {
    test('chaque entrée produit une Resistance valide', () {
      expect(kResistanceCreationTemplates, isNotEmpty);
      for (var i = 0; i < kResistanceCreationTemplates.length; i++) {
        final t = kResistanceCreationTemplates[i];
        expect(
          () => Resistance(
            id: 'template-$i',
            title: t.title,
            description: t.description,
            createdAtUtc: createdAtUtc,
            emoji: t.emoji,
          ),
          returnsNormally,
          reason: 'template #$i (${t.title})',
        );
        expect(
          t.title.trim().length,
          lessThanOrEqualTo(Resistance.maxTitleLength),
        );
        expect(
          t.description.length,
          lessThanOrEqualTo(Resistance.maxDescriptionLength),
        );
        expect(t.emoji.trim(), isNotEmpty);
      }
    });

    test('titres uniques pour que l’index de suggestion soit déterministe', () {
      final titles = kResistanceCreationTemplates
          .map((e) => e.title)
          .toList(growable: false);
      expect(titles.toSet().length, titles.length);
    });
  });
}
