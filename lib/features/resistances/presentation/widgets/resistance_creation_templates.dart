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
    emoji: '🍺',
    title: 'Arrêter l\'alcool',
    description:
        "L'OMS ne définit aucun seuil sans risque. Chaque jour sans alcool réduit la pression artérielle et améliore la qualité du sommeil.",
  ),
  ResistanceCreationTemplate(
    emoji: '🎰',
    title: "Arrêter les jeux d'argent",
    description:
        "Les jeux d'argent activent les mêmes circuits dopaminergiques que les drogues dures. Chaque jour sans jouer renforce le contrôle impulsif.",
  ),
];
