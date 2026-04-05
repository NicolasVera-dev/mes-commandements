import 'package:flutter/material.dart';

typedef EmojiChanged = void Function(String emoji);

/// Jeu d’emojis proposés dans la feuille (commandements vs résistances / addictions).
enum EmojiPickerPreset {
  commands,
  resistanceAddictions,
}

class EmojiPickerField extends StatelessWidget {
  final String selectedEmoji;
  final EmojiChanged onChanged;
  final EmojiPickerPreset preset;

  const EmojiPickerField({
    super.key,
    required this.selectedEmoji,
    required this.onChanged,
    this.preset = EmojiPickerPreset.commands,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = preset == EmojiPickerPreset.resistanceAddictions
        ? 'Icônes fréquentes pour les habitudes à arrêter'
        : 'Personnaliser l’icône du commandement';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        child: Text(
          selectedEmoji,
          style: const TextStyle(fontSize: 20),
        ),
      ),
      title: const Text('Emoji'),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () async {
        final selected = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => _EmojiPickerSheet(
            initialEmoji: selectedEmoji,
            preset: preset,
          ),
        );
        if (selected == null) return;
        onChanged(selected);
      },
    );
  }
}

class _EmojiPickerSheet extends StatefulWidget {
  final String initialEmoji;
  final EmojiPickerPreset preset;

  const _EmojiPickerSheet({
    required this.initialEmoji,
    required this.preset,
  });

  @override
  State<_EmojiPickerSheet> createState() => _EmojiPickerSheetState();
}

class _EmojiPickerSheetState extends State<_EmojiPickerSheet> {
  late String _selectedEmoji;
  String _query = '';

  static const Map<String, List<String>> _commandCategories =
      <String, List<String>>{
    'Sport': <String>['🏃', '🏋️', '🚴', '⚽', '🏀', '🥇', '🧘', '🎾'],
    'Santé': <String>['💧', '🥗', '💊', '😴', '🫀', '🧠', '🚶', '🩺'],
    'Travail': <String>['💼', '🗂️', '🧑‍💻', '📚', '📝', '📈', '✅', '🧾'],
    'Créativité': <String>['🎨', '🎵', '🧵', '📷', '✍️', '🧩', '🎬', '🛠️'],
    'Social': <String>['👨‍👩‍👧', '🤝', '☎️', '💬', '🎉', '❤️', '🙏', '☕'],
    'Autres': <String>['🎯', '⭐', '🔥', '🌱', '🚀', '⏱️', '📌', '💡'],
  };

  /// Tabac, alcool, contenu adulte, écrans, jeux, nourriture, etc.
  static const Map<String, List<String>> _addictionCategories =
      <String, List<String>>{
    'Tabac & vape': <String>['🚬', '🚭', '🫁', '💨'],
    'Alcool': <String>['🍺', '🍷', '🥃', '🍸', '🍾', '🤢'],
    'Contenu sensible': <String>['🔞', '⚠️', '🔒'],
    'Écrans & web': <String>['📱', '💻', '📺', '🌐', '📲', '👁️'],
    'Jeux & paris': <String>['🎰', '🎲', '🃏', '🎮', '🕹️'],
    'Nourriture': <String>['🍔', '🍟', '🍕', '🍫', '🧁', '🍩', '🥤'],
    'Substances': <String>['💊', '💉', '🧪'],
    'Autres': <String>['🛡️', '⛔', '🧠', '💪', '😤', '🧘', '💅', '🤚', '✋', '🦷', '🦶'],
  };

  Map<String, List<String>> get _categories {
    switch (widget.preset) {
      case EmojiPickerPreset.commands:
        return _commandCategories;
      case EmojiPickerPreset.resistanceAddictions:
        return _addictionCategories;
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedEmoji = widget.initialEmoji;
  }

  @override
  Widget build(BuildContext context) {
    final normalized = _query.trim();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 8,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choisir un emoji',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: (value) => setState(() => _query = value),
                textCapitalization: TextCapitalization.none,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Rechercher un emoji...',
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      _selectedEmoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  title: const Text('Aperçu'),
                  subtitle: const Text('Emoji sélectionné'),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: _categories.entries
                      .map((entry) {
                        final emojis = entry.value
                            .where((e) => normalized.isEmpty || e.contains(normalized))
                            .toList(growable: false);
                        if (emojis.isEmpty) return const SizedBox.shrink();
                        return _EmojiCategorySection(
                          title: entry.key,
                          emojis: emojis,
                          selectedEmoji: _selectedEmoji,
                          onTapEmoji: (emoji) => setState(() => _selectedEmoji = emoji),
                        );
                      })
                      .where((w) => w is! SizedBox)
                      .toList(growable: false),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(_selectedEmoji),
                  child: const Text('Valider'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmojiCategorySection extends StatelessWidget {
  final String title;
  final List<String> emojis;
  final String selectedEmoji;
  final ValueChanged<String> onTapEmoji;

  const _EmojiCategorySection({
    required this.title,
    required this.emojis,
    required this.selectedEmoji,
    required this.onTapEmoji,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: emojis.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final emoji = emojis[index];
              final selected = selectedEmoji == emoji;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onTapEmoji(emoji),
                child: Ink(
                  decoration: BoxDecoration(
                    color: selected
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.18)
                        : Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
