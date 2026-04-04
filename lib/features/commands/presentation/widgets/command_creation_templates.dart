import 'package:meta/meta.dart';

import '../../domain/entities/command.dart';

@immutable
class CommandCreationTemplate {
  final String emoji;
  final String title;
  final String description;
  final Frequency frequency;
  final int target;

  const CommandCreationTemplate({
    required this.emoji,
    required this.title,
    required this.description,
    required this.frequency,
    required this.target,
  });
}

/// Modèles pré-remplis pour la création de commandement (const, hors réseau).
const List<CommandCreationTemplate> kCommandCreationTemplates =
    <CommandCreationTemplate>[
  CommandCreationTemplate(
    emoji: '🚶',
    title: '8 000 pas par jour',
    description:
        "Les études montrent qu'atteindre 8 000 pas/jour réduit de 51 % le risque de mortalité prématurée (JAMA, 2021).",
    frequency: Frequency.daily,
    target: 1,
  ),
  CommandCreationTemplate(
    emoji: '🏋️',
    title: '3 séances de sport',
    description:
        "L'OMS recommande 150 min d'activité modérée par semaine. 3 séances suffisent pour atteindre ce seuil et améliorer durablement santé cardiaque et humeur.",
    frequency: Frequency.weekly,
    target: 3,
  ),
  CommandCreationTemplate(
    emoji: '🎬',
    title: '2 grands films du cinéma',
    description:
        "S'exposer régulièrement à des œuvres marquantes élargit l'empathie, la culture générale et la capacité d'analyse.",
    frequency: Frequency.monthly,
    target: 2,
  ),
];
