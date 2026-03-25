import 'package:flutter/material.dart';

class DynamicProgressBar extends StatelessWidget {
  final int progress;
  final int target;

  const DynamicProgressBar({
    super.key,
    required this.progress,
    required this.target,
  });

  double get _ratio {
    if (target <= 0) return 0.0;
    final value = progress / target;
    return value.clamp(0.0, 1.0);
  }

  Color _progressColor(BuildContext context) {
    if (_ratio < 0.5) return Colors.redAccent;
    if (_ratio < 0.8) return Colors.orangeAccent;
    return Colors.greenAccent.shade200;
  }

  @override
  Widget build(BuildContext context) {
    final color = _progressColor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$progress / $target',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          tween: Tween<double>(begin: 0, end: _ratio),
          builder: (context, value, _) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 10,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
              ),
            );
          },
        ),
      ],
    );
  }
}

