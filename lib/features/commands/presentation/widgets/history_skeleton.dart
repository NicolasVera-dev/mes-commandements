import 'package:flutter/material.dart';

class HistorySkeleton extends StatefulWidget {
  const HistorySkeleton({super.key});

  @override
  State<HistorySkeleton> createState() => _HistorySkeletonState();
}

class _HistorySkeletonState extends State<HistorySkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final alpha = 0.08 + (0.08 * _controller.value);
        final color = Theme.of(context).colorScheme.onSurface.withValues(alpha: alpha);
        return Column(
          children: List.generate(
            4,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
