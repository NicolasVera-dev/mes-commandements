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
  CommandCreationTemplate(
    emoji: '💧',
    title: "Boire 1,5L d'eau",
    description:
        "Une hydratation suffisante améliore la concentration, l'énergie et la digestion. L'OMS recommande 1,5 à 2L par jour.",
    frequency: Frequency.daily,
    target: 1,
  ),
  CommandCreationTemplate(
    emoji: '🧘',
    title: '10 min de méditation',
    description:
        "10 minutes de pleine conscience par jour réduisent significativement le stress et améliorent la régulation émotionnelle (Harvard Medical School).",
    frequency: Frequency.daily,
    target: 1,
  ),
  CommandCreationTemplate(
    emoji: '📖',
    title: 'Lire 20 minutes',
    description:
        "Lire quotidiennement réduit le stress de 68 % en 6 minutes selon une étude de l'Université de Sussex. 20 minutes suffisent pour progresser durablement.",
    frequency: Frequency.daily,
    target: 1,
  ),
  CommandCreationTemplate(
    emoji: '🌙',
    title: 'Au lit avant 23h',
    description:
        "Un sommeil régulier avant minuit améliore la qualité des cycles de sommeil profond, essentiels à la mémoire et à la récupération.",
    frequency: Frequency.daily,
    target: 1,
  ),
  CommandCreationTemplate(
    emoji: '📞',
    title: 'Appeler un proche',
    description:
        "Maintenir des liens sociaux forts est l'un des meilleurs prédicteurs de longévité et de bonheur (étude Harvard sur 80 ans).",
    frequency: Frequency.weekly,
    target: 1,
  ),
  CommandCreationTemplate(
    emoji: '🌿',
    title: 'Sortie dans la nature',
    description:
        "S'exposer à la nature 2h par semaine est associé à un meilleur bien-être physique et mental (Nature, 2019).",
    frequency: Frequency.weekly,
    target: 2,
  ),
  CommandCreationTemplate(
    emoji: '📚',
    title: 'Finir un livre',
    description:
        "Lire un livre par mois représente 12 livres par an. Les grands lecteurs développent un vocabulaire, une mémoire et une empathie supérieurs.",
    frequency: Frequency.monthly,
    target: 1,
  ),
  CommandCreationTemplate(
    emoji: '🎨',
    title: 'Activité créative',
    description:
        "Peindre, dessiner, écrire… La pratique créative régulière réduit le cortisol et stimule la neuroplasticité.",
    frequency: Frequency.monthly,
    target: 2,
  ),
  CommandCreationTemplate(
    emoji: '✈️',
    title: 'Partir en voyage',
    description:
        "Voyager au moins une fois par an expose à de nouvelles cultures, stimule la curiosité et renforce la résilience face à l'imprévu.",
    frequency: Frequency.yearly,
    target: 1,
  ),
  CommandCreationTemplate(
    emoji: '🧗',
    title: 'Relever un défi physique',
    description:
        "Se fixer un défi sportif annuel — marathon, randonnée, triathlon — structure la motivation sur le long terme et renforce la confiance en soi.",
    frequency: Frequency.yearly,
    target: 1,
  ),
  CommandCreationTemplate(
    emoji: '💡',
    title: 'Apprendre quelque chose de nouveau',
    description:
        "Acquérir une nouvelle compétence chaque année — langue, instrument, programmation — entretient la neuroplasticité et élargit les opportunités.",
    frequency: Frequency.yearly,
    target: 1,
  ),
];
