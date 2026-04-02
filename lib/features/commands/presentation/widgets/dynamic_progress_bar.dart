import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';

class DynamicProgressBar extends StatefulWidget {
  final int progress;
  final int target;
  final Color? accentTintColor;

  /// Réduit texte et hauteur de barre (cartes compactes).
  final bool compact;

  const DynamicProgressBar({
    super.key,
    required this.progress,
    required this.target,
    this.accentTintColor,
    this.compact = false,
  });

  @override
  State<DynamicProgressBar> createState() => _DynamicProgressBarState();
}

class _DynamicProgressBarState extends State<DynamicProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweepController;
  late final Animation<double> _sweepOffset;
  late final Animation<double> _sweepOpacity;
  late double _previousRatio;

  double get _ratio {
    if (widget.target <= 0) return 0.0;
    final value = widget.progress / widget.target;
    return value.clamp(0.0, 1.0);
  }

  double _ratioFor({
    required int progress,
    required int target,
  }) {
    if (target <= 0) return 0.0;
    final value = progress / target;
    return value.clamp(0.0, 1.0);
  }

  Color _progressColor(BuildContext context) {
    final semanticColors = Theme.of(context).extension<AppSemanticColors>();
    final base = _ratio < 0.5
        ? (semanticColors?.progressLow ?? Theme.of(context).colorScheme.error)
        : (_ratio < 0.8
            ? (semanticColors?.progressMedium ??
                Theme.of(context).colorScheme.tertiary)
            : (semanticColors?.progressHigh ??
                Theme.of(context).colorScheme.primary));
    final accent = widget.accentTintColor;
    if (accent == null) return base;
    // Teinte subtile en conservant la lisibilité des seuils de progression.
    return Color.alphaBlend(accent.withValues(alpha: 0.22), base);
  }

  @override
  void initState() {
    super.initState();
    _previousRatio = _ratio;
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _sweepOffset = Tween<double>(begin: -1.1, end: 1.1).animate(
      CurvedAnimation(parent: _sweepController, curve: Curves.easeOutCubic),
    );
    _sweepOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 0.22),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.22, end: 0),
        weight: 65,
      ),
    ]).animate(_sweepController);
  }

  @override
  void didUpdateWidget(covariant DynamicProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldRatio = _ratioFor(
      progress: oldWidget.progress,
      target: oldWidget.target,
    );
    final newRatio = _ratio;
    if (oldRatio != newRatio) {
      _previousRatio = oldRatio;
    }
    if (widget.progress > oldWidget.progress) {
      _sweepController
        ..stop()
        ..forward(from: 0);
    }
  }

  @override
  void dispose() {
    _sweepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _progressColor(context);
    final barH = widget.compact ? 6.0 : 10.0;
    final ratioStyle = widget.compact
        ? Theme.of(context).textTheme.labelLarge
        : Theme.of(context).textTheme.titleMedium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.progress} / ${widget.target}',
          style: ratioStyle,
        ),
        SizedBox(height: widget.compact ? 4 : 6),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          tween: Tween<double>(begin: _previousRatio, end: _ratio),
          onEnd: () {
            _previousRatio = _ratio;
          },
          builder: (context, value, _) {
            return SizedBox(
              height: barH,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    LinearProgressIndicator(
                      value: value,
                      minHeight: barH,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                    ),
                    AnimatedBuilder(
                      animation: _sweepController,
                      builder: (context, child) {
                        if (_sweepController.isDismissed) {
                          return const SizedBox.shrink();
                        }
                        return FractionalTranslation(
                          translation: Offset(_sweepOffset.value, 0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: 26,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context)
                                        .colorScheme
                                        .onPrimary
                                        .withValues(alpha: 0),
                                    Theme.of(context)
                                        .colorScheme
                                        .onPrimary
                                        .withValues(alpha: _sweepOpacity.value),
                                    Theme.of(context)
                                        .colorScheme
                                        .onPrimary
                                        .withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

