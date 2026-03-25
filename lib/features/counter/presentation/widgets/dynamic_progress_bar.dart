import 'package:flutter/material.dart';

class DynamicProgressBar extends StatefulWidget {
  final int progress;
  final int target;

  const DynamicProgressBar({
    super.key,
    required this.progress,
    required this.target,
  });

  @override
  State<DynamicProgressBar> createState() => _DynamicProgressBarState();
}

class _DynamicProgressBarState extends State<DynamicProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweepController;
  late final Animation<double> _sweepOffset;
  late final Animation<double> _sweepOpacity;

  double get _ratio {
    if (widget.target <= 0) return 0.0;
    final value = widget.progress / widget.target;
    return value.clamp(0.0, 1.0);
  }

  Color _progressColor(BuildContext context) {
    if (_ratio < 0.5) return Colors.redAccent;
    if (_ratio < 0.8) return Colors.orangeAccent;
    return Colors.greenAccent.shade200;
  }

  @override
  void initState() {
    super.initState();
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.progress} / ${widget.target}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          tween: Tween<double>(begin: 0, end: _ratio),
          builder: (context, value, _) {
            return SizedBox(
              height: 10,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    LinearProgressIndicator(
                      value: value,
                      minHeight: 10,
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
                                    Colors.white.withValues(alpha: 0),
                                    Colors.white.withValues(alpha: _sweepOpacity.value),
                                    Colors.white.withValues(alpha: 0),
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

