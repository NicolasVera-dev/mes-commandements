import 'package:meta/meta.dart';

@immutable
class ResistanceCreationTemplate {
  final String emoji;
  final String title;
  final String description;

  const ResistanceCreationTemplate({
    required this.emoji,
    required this.title,
    required this.description,
  });
}

/// Modèles pré-remplis pour la création de résistance (const, hors réseau).
const List<ResistanceCreationTemplate> kResistanceCreationTemplates =
    <ResistanceCreationTemplate>[
  ResistanceCreationTemplate(
    emoji: '🚬',
    title: 'Arrêter de fumer',
    description:
        "Après 72h sans fumer, les bronches commencent à se régénérer. Après 1 an, le risque d'infarctus est divisé par deux.",
  ),
  ResistanceCreationTemplate(
    emoji: '🌙',
    title: 'Arrêter les écrans après 21h',
    description:
        "La lumière bleue bloque la mélatonine et retarde l'endormissement de 1 à 3h. Couper les écrans le soir améliore profondément le sommeil.",
  ),
];
