import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';

typedef AccentColorChanged = void Function(int? colorValue);
const String _useThemeDefaultColorToken = '__use_theme_default_color__';

class AccentColorPickerField extends StatelessWidget {
  final int? selectedColorValue;
  final String emojiPreview;
  final AccentColorChanged onChanged;

  const AccentColorPickerField({
    super.key,
    required this.selectedColorValue,
    required this.emojiPreview,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = selectedColorValue == null ? null : Color(selectedColorValue!);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color ?? Theme.of(context).colorScheme.primary,
        child: Text(emojiPreview),
      ),
      title: const Text('Couleur d’accent'),
      subtitle: const Text('Personnaliser la couleur du commandement'),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () async {
        final selected = await showModalBottomSheet<Object?>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => _AccentColorPickerSheet(
            initialColorValue: selectedColorValue,
            emojiPreview: emojiPreview,
          ),
        );
        if (selected == _useThemeDefaultColorToken) {
          onChanged(null);
          return;
        }
        if (selected is int) onChanged(selected);
      },
    );
  }
}

class _AccentColorPickerSheet extends StatefulWidget {
  final int? initialColorValue;
  final String emojiPreview;

  const _AccentColorPickerSheet({
    required this.initialColorValue,
    required this.emojiPreview,
  });

  @override
  State<_AccentColorPickerSheet> createState() => _AccentColorPickerSheetState();
}

class _AccentColorPickerSheetState extends State<_AccentColorPickerSheet> {
  static const List<Color> _materialPalette = <Color>[
    Color(0xFF6750A4),
    Color(0xFF4F378B),
    Color(0xFF006A6A),
    Color(0xFF1565C0),
    Color(0xFF2E7D32),
    Color(0xFFEF6C00),
    Color(0xFFC62828),
    Color(0xFFAD1457),
    Color(0xFF6D4C41),
    Color(0xFF455A64),
  ];

  late Color _selectedColor;
  late Color _themeDefaultColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = const Color(0xFF6750A4);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _themeDefaultColor = Theme.of(context).colorScheme.primary;
    _selectedColor = widget.initialColorValue == null
        ? _themeDefaultColor
        : Color(widget.initialColorValue!);
  }

  bool _passesContrast(Color color, BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final ratio = _contrastRatio(color, surface);
    return ratio >= 4.5;
  }

  double _contrastRatio(Color a, Color b) {
    final l1 = a.computeLuminance();
    final l2 = b.computeLuminance();
    final light = l1 > l2 ? l1 : l2;
    final dark = l1 > l2 ? l2 : l1;
    return (light + 0.05) / (dark + 0.05);
  }

  @override
  Widget build(BuildContext context) {
    final validContrast = _passesContrast(_selectedColor, context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.84,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choisir une couleur d’accent',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _CommandCardMiniaturePreview(
                accentColor: _selectedColor,
                emoji: widget.emojiPreview,
                validContrast: validContrast,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: ColorPicker(
                    color: _selectedColor,
                    onColorChanged: (color) => setState(() => _selectedColor = color),
                    enableShadesSelection: false,
                    pickersEnabled: const <ColorPickerType, bool>{
                      ColorPickerType.wheel: false,
                      ColorPickerType.primary: true,
                      ColorPickerType.accent: false,
                      ColorPickerType.bw: false,
                      ColorPickerType.custom: true,
                    },
                    customColorSwatchesAndNames: <ColorSwatch<Object>, String>{
                      for (final color in _materialPalette) ColorTools.createPrimarySwatch(color): '',
                    },
                  ),
                ),
              ),
              if (!validContrast)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Contraste faible détecté (WCAG AA). Vous pouvez continuer, mais la lisibilité peut être réduite.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.of(context).pop(_useThemeDefaultColorToken),
                      child: const Text('Couleur par défaut (thème)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () =>
                          Navigator.of(context).pop(_selectedColor.toARGB32()),
                      child: const Text('Valider'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommandCardMiniaturePreview extends StatelessWidget {
  final Color accentColor;
  final String emoji;
  final bool validContrast;

  const _CommandCardMiniaturePreview({
    required this.accentColor,
    required this.emoji,
    required this.validContrast,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: validContrast ? 0.9 : 0.4),
          width: 1.4,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: accentColor.withValues(alpha: 0.2),
            child: Text(emoji),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Aperçu du commandement',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Icon(
            validContrast ? Icons.check_circle_outline : Icons.warning_amber_rounded,
            color: validContrast
                ? Theme.of(context).colorScheme.tertiary
                : Theme.of(context).colorScheme.error,
          ),
        ],
      ),
    );
  }
}
