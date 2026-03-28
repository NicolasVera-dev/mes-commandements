import 'package:flutter/material.dart';

typedef EmojiChanged = void Function(String emoji);

class EmojiPickerField extends StatelessWidget {
  final String selectedEmoji;
  final EmojiChanged onChanged;

  const EmojiPickerField({
    super.key,
    required this.selectedEmoji,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        child: Text(
          selectedEmoji,
          style: const TextStyle(fontSize: 20),
        ),
      ),
      title: const Text('Emoji'),
      subtitle: const Text('Personnaliser l’icône du commandement'),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () async {
        final selected = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => _EmojiPickerSheet(initialEmoji: selectedEmoji),
        );
        if (selected == null) return;
        onChanged(selected);
      },
    );
  }
}

class _EmojiPickerSheet extends StatefulWidget {
  final String initialEmoji;

  const _EmojiPickerSheet({
    required this.initialEmoji,
  });

  @override
  State<_EmojiPickerSheet> createState() => _EmojiPickerSheetState();
}

class _EmojiPickerSheetState extends State<_EmojiPickerSheet> {
  late String _selectedEmoji;
  String _query = '';

  static const Map<String, List<String>> _categories = <String, List<String>>{
    'Sport': <String>['🏃', '🏋️', '🚴', '⚽', '🏀', '🥇', '🧘', '🎾'],
    'Santé': <String>['💧', '🥗', '💊', '😴', '🫀', '🧠', '🚶', '🩺'],
    'Travail': <String>['💼', '🗂️', '🧑‍💻', '📚', '📝', '📈', '✅', '🧾'],
    'Créativité': <String>['🎨', '🎵', '🧵', '📷', '✍️', '🧩', '🎬', '🛠️'],
    'Social': <String>['👨‍👩‍👧', '🤝', '☎️', '💬', '🎉', '❤️', '🙏', '☕'],
    'Autres': <String>['🎯', '⭐', '🔥', '🌱', '🚀', '⏱️', '📌', '💡'],
  };

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
