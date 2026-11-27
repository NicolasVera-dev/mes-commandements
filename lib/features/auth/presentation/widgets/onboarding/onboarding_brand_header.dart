import 'package:flutter/material.dart';

/// Kept outside the PageView so the brand never moves with the slides.
class OnboardingBrandHeader extends StatelessWidget {
  const OnboardingBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Semantics(
        header: true,
        label: 'Rituel',
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                'assets/images/icon_launcher.png',
                width: 52,
                height: 52,
                excludeFromSemantics: true,
              ),
            ),
            const SizedBox(width: 14),
            Flexible(
              child: Text(
                'RITUEL',
                maxLines: 1,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3.5,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
