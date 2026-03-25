import 'package:flutter/material.dart';

class IncrementAnimationOverlay extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool enabled;
  final BorderRadius borderRadius;

  const IncrementAnimationOverlay({
    super.key,
    required this.child,
    required this.onTap,
    this.enabled = true,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  @override
  State<IncrementAnimationOverlay> createState() =>
      _IncrementAnimationOverlayState();
}

class _IncrementAnimationOverlayState extends State<IncrementAnimationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _cardScale;
  late final Animation<double> _borderOpacity;
  late final Animation<double> _badgeOpacity;
  late final Animation<Offset> _badgeOffset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    // 1) Pulse léger de la carte.
    _cardScale = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.0, end: 1.012)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 45,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.012, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 55,
      ),
    ]).animate(_controller);

    // 2) Flash de bordure.
    _borderOpacity = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: 0.45)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.45, end: 0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 70,
      ),
    ]).animate(_controller);

    // 3) Badge +1 discret.
    _badgeOpacity = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: 1)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(1),
        weight: 20,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1, end: 0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 55,
      ),
    ]).animate(_controller);
    _badgeOffset = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: const Offset(0, -0.2),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.enabled) return;
    widget.onTap();
    _controller
      ..stop()
      ..forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ScaleTransition(
      scale: _cardScale,
      child: InkWell(
        onTap: widget.enabled ? _handleTap : null,
        borderRadius: widget.borderRadius,
        child: Stack(
          children: [
            widget.child,
            IgnorePointer(
              child: FadeTransition(
                opacity: _borderOpacity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: widget.borderRadius,
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.8),
                      width: 1.4,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 10,
              child: IgnorePointer(
                child: FadeTransition(
                  opacity: _badgeOpacity,
                  child: SlideTransition(
                    position: _badgeOffset,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '+1',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

