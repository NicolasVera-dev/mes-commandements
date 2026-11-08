import 'package:flutter/material.dart';

Future<bool> confirmCommandDeletion(BuildContext context) =>
    _confirmCommandAction(
      context,
      title: 'Supprimer le commandement ?',
      message: 'Le commandement et son historique seront supprimés.',
      action: 'Supprimer',
    );

Future<bool> confirmCommandReset(BuildContext context) => _confirmCommandAction(
  context,
  title: 'Réinitialiser le cycle ?',
  message: 'La progression du cycle en cours sera remise à zéro.',
  action: 'Réinitialiser',
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
                child: const Text('Annuler'),
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
