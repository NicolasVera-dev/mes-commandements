import 'dart:async';

import 'package:flutter/material.dart';

/// Barre de recherche repliable (titres [collapsedTitle] + champ étendu).
/// La requête est pilotée par le parent ([searchQuery] / [onSearchQueryChanged]).
class ExpandableSearchBar extends StatefulWidget {
  final String collapsedTitle;
  final String searchQuery;
  final ValueChanged<String> onSearchQueryChanged;
  final String hintText;

  const ExpandableSearchBar({
    super.key,
    required this.collapsedTitle,
    required this.searchQuery,
    required this.onSearchQueryChanged,
    this.hintText = 'Rechercher…',
  });

  @override
  State<ExpandableSearchBar> createState() => _ExpandableSearchBarState();
}

class _ExpandableSearchBarState extends State<ExpandableSearchBar> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(covariant ExpandableSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery &&
        widget.searchQuery != _controller.text &&
        !_focusNode.hasFocus) {
      _controller.text = widget.searchQuery;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _open() {
    if (_expanded) return;
    setState(() => _expanded = true);
    Future.microtask(() {
      if (!mounted) return;
      _focusNode.requestFocus();
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    });
  }

  void _close({required bool unfocusKeyboard}) {
    if (!_expanded) return;
    _debounce?.cancel();
    setState(() => _expanded = false);
    if (unfocusKeyboard) {
      _focusNode.unfocus();
    }
  }

  void _commitQuery(String value) {
    widget.onSearchQueryChanged(value.trim());
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _commitQuery(value);
    });
  }

  void _clearAndClose() {
    _debounce?.cancel();
    _controller.clear();
    _commitQuery('');
    _close(unfocusKeyboard: true);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: !_expanded,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _expanded) {
          _close(unfocusKeyboard: true);
        }
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
          return FadeTransition(
            opacity: curved,
            child: SizeTransition(
              sizeFactor: curved,
              axis: Axis.horizontal,
              axisAlignment: -1,
              child: child,
            ),
          );
        },
        child: _expanded
            ? _SearchField(
                key: const ValueKey('searchExpanded'),
                colorScheme: colorScheme,
                controller: _controller,
                focusNode: _focusNode,
                hintText: widget.hintText,
                onChanged: _onChanged,
                onClear: _clearAndClose,
                onClose: () => _close(unfocusKeyboard: true),
              )
            : _CollapsedTitle(
                key: const ValueKey('searchCollapsed'),
                collapsedTitle: widget.collapsedTitle,
                onSearchTap: _open,
              ),
      ),
    );
  }
}

class _CollapsedTitle extends StatelessWidget {
  final String collapsedTitle;
  final VoidCallback onSearchTap;

  const _CollapsedTitle({
    super.key,
    required this.collapsedTitle,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey('collapsedRow'),
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            collapsedTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  height: 1.12,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.search_rounded),
          tooltip: 'Rechercher',
          onPressed: onSearchTap,
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onClose;
  final ColorScheme colorScheme;
  final String hintText;

  const _SearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
    required this.onClose,
    required this.colorScheme,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final hasText = value.text.isNotEmpty;

        return Container(
          width: double.infinity,
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(23),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: true,
            onChanged: onChanged,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.search,
            maxLines: 1,
            minLines: 1,
            keyboardType: TextInputType.text,
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: InputBorder.none,
              prefixIconConstraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: hasText
                  ? IconButton(
                      tooltip: 'Effacer',
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      onPressed: onClear,
                    )
                  : IconButton(
                      tooltip: 'Fermer',
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: onClose,
                    ),
            ),
          ),
        );
      },
    );
  }
}
