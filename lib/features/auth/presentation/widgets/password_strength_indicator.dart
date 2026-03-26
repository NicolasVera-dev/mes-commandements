import 'package:flutter/material.dart';

import '../../domain/validators/password_validator.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final PasswordValidationResult result;
  final bool showFirstError;

  const PasswordStrengthIndicator({
    super.key,
    required this.result,
    this.showFirstError = true,
  });

  Color _strengthColor(PasswordValidationResult r) {
    final total = r.rules.length;
    final ratio = total == 0 ? 0.0 : r.satisfiedRulesCount / total;

    if (ratio < 0.5) return Colors.redAccent;
    if (ratio < 0.8) return Colors.orangeAccent;
    return Colors.greenAccent.shade200;
  }

  @override
  Widget build(BuildContext context) {
    final total = result.rules.length;
    final ratio = total == 0 ? 0.0 : result.satisfiedRulesCount / total;
    final strengthColor = _strengthColor(result);

    final firstErrorMessage = result.rules
        .firstWhere((rule) => !rule.isValid, orElse: () => result.rules.first)
        .errorMessage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Force : ${result.strengthLabel}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          ),
        ),
        const SizedBox(height: 10),
        ...result.rules.map((rule) {
          final icon = rule.isValid
              ? Icons.check_circle_rounded
              : Icons.cancel_rounded;
          final iconColor = rule.isValid
              ? Colors.greenAccent.shade200
              : Theme.of(context).colorScheme.errorContainer;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rule.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: rule.isValid
                              ? Theme.of(context).colorScheme.onSurfaceVariant
                              : Theme.of(context).colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.85),
                        ),
                  ),
                ),
              ],
            ),
          );
        }),
        if (showFirstError &&
            result.rules.any((r) => !r.isValid) &&
            (firstErrorMessage != null && firstErrorMessage.isNotEmpty))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              firstErrorMessage,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }
}

