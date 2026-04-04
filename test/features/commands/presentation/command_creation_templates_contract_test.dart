import 'package:flutter_test/flutter_test.dart';
import 'package:mes_commandements/features/commands/domain/entities/command.dart';
import 'package:mes_commandements/features/commands/presentation/widgets/command_creation_templates.dart';

/// Garantit que chaque modèle UI reste compatible avec les assertions du domaine.
void main() {
  group('kCommandCreationTemplates', () {
    test('chaque entrée produit un Command valide', () {
      expect(kCommandCreationTemplates, isNotEmpty);
      for (var i = 0; i < kCommandCreationTemplates.length; i++) {
        final t = kCommandCreationTemplates[i];
        expect(
          () => Command(
            id: 'template-$i',
            title: t.title,
            description: t.description,
            target: t.target,
            progress: 0,
            frequency: t.frequency,
            emoji: t.emoji,
          ),
          returnsNormally,
          reason: 'template #$i (${t.title})',
        );
        expect(t.title.trim().length, lessThanOrEqualTo(Command.maxTitleLength));
        expect(
          t.description.length,
          lessThanOrEqualTo(Command.maxDescriptionLength),
        );
        expect(t.target, greaterThan(0));
        expect(t.emoji.trim(), isNotEmpty);
      }
    });

    test('titres uniques pour que l’index de suggestion soit déterministe', () {
      final titles =
          kCommandCreationTemplates.map((e) => e.title).toList(growable: false);
      expect(titles.toSet().length, titles.length);
    });
  });
}
