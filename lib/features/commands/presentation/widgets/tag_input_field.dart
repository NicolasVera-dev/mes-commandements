import 'package:flutter/material.dart';

import '../../domain/entities/command.dart';

typedef TagsChanged = void Function(List<String> tags);

class TagInputField extends StatefulWidget {
  final List<String> initialTags;
  final List<String> suggestions;
  final int? accentColorValue;
  final TagsChanged onChanged;

  const TagInputField({
    super.key,
    required this.initialTags,
    required this.suggestions,
    required this.onChanged,
    this.accentColorValue,
  });

  @override
  State<TagInputField> createState() => _TagInputFieldState();
}

class _TagInputFieldState extends State<TagInputField> {
  TextEditingController? _inputController;
  late List<String> _tags;
  String? _inputError;

  @override
  void initState() {
    super.initState();
    _tags = List<String>.from(widget.initialTags);
  }

  @override
  void didUpdateWidget(covariant TagInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTags != widget.initialTags) {
      _tags = List<String>.from(widget.initialTags);
    }
  }

  void _addTag(String raw) {
    final tag = raw.trim();
    if (tag.isEmpty) return;
    if (tag.length > Command.maxTagLength) {
      setState(
        () => _inputError =
            'Un tag ne peut pas dépasser ${Command.maxTagLength} caractères.',
      );
      return;
    }
    if (_tags.contains(tag)) {
      setState(() => _inputError = 'Ce tag existe déjà.');
      return;
    }
    if (_tags.length >= Command.maxTagsCount) {
      setState(
        () => _inputError =
            'Maximum ${Command.maxTagsCount} tags par commandement.',
      );
      return;
    }

    setState(() {
      _tags.add(tag);
      _inputError = null;
      _inputController?.clear();
    });
    widget.onChanged(List<String>.from(_tags));
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
      _inputError = null;
    });
    widget.onChanged(List<String>.from(_tags));
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColorValue == null
        ? Theme.of(context).colorScheme.primary
        : Color(widget.accentColorValue!);
    final suggestions = widget.suggestions
        .where((tag) => !_tags.contains(tag))
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Autocomplete<String>(
          optionsBuilder: (textEditingValue) {
            final q = textEditingValue.text.trim().toLowerCase();
            if (q.isEmpty) return const Iterable<String>.empty();
            return suggestions
                .where((tag) => tag.toLowerCase().contains(q))
                .take(8);
          },
          onSelected: _addTag,
          fieldViewBuilder: (
            context,
            textEditingController,
            focusNode,
            onFieldSubmitted,
          ) {
            _inputController = textEditingController;
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              textCapitalization: TextCapitalization.none,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                onFieldSubmitted();
                _addTag(textEditingController.text);
              },
              decoration: InputDecoration(
                labelText: 'Tags',
                hintText: 'Ajouter un tag (autocomplétion)',
                prefixIcon: const Icon(Icons.sell_outlined),
                errorText: _inputError,
                helperText:
                    '${_tags.length}/${Command.maxTagsCount} tags • ${Command.maxTagLength} caractères max',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_rounded),
                  onPressed: () => _addTag(textEditingController.text),
                  tooltip: 'Ajouter le tag',
                ),
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360, maxHeight: 220),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.tag_rounded, size: 18),
                        title: Text(option),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        if (_tags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags
                .map(
                  (tag) => Chip(
                    label: Text(tag),
                    onDeleted: () => _removeTag(tag),
                    backgroundColor: accent.withValues(alpha: 0.16),
                    side: BorderSide(color: accent.withValues(alpha: 0.6)),
                  ),
                )
                .toList(growable: false),
          ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'Suggestions',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions
                .take(12)
                .map(
                  (tag) => ActionChip(
                    label: Text(tag),
                    onPressed: () => _addTag(tag),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ],
    );
  }
}
