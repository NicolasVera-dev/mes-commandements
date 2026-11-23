import 'package:flutter/material.dart';

import '../../../../app/localization/localization.dart';

Future<bool> confirmCommandDeletion(BuildContext context) =>
    _confirmCommandAction(
      context,
      title: context.l10n.supprimerLeCommandement,
      message: context.l10n.leCommandementEtSonHistoriqueSerontSupprimes,
      action: context.l10n.supprimer,
    );

Future<bool> confirmCommandReset(BuildContext context) => _confirmCommandAction(
  context,
  title: context.l10n.reinitialiserLeCycle,
  message: context.l10n.laProgressionDuCycleEnCoursSeraRemiseA,
  action: context.l10n.reinitialiser,
);

Future<bool> _confirmCommandAction(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          final colors = Theme.of(dialogContext).colorScheme;
          return AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(context.l10n.annuler),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: colors.errorContainer,
                  foregroundColor: colors.onErrorContainer,
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(action),
              ),
            ],
          );
        },
      ) ??
      false;
}
