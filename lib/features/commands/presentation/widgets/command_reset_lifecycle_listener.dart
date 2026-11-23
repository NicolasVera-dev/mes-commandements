import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/command.dart';
import '../state/command_provider.dart';
import '../../../../app/localization/localization.dart';

/// Déclenche le reset auto au lancement puis à chaque retour au premier plan.
class CommandResetLifecycleListener extends StatefulWidget {
  final Widget child;

  const CommandResetLifecycleListener({super.key, required this.child});

  @override
  State<CommandResetLifecycleListener> createState() =>
      _CommandResetLifecycleListenerState();
}

class _CommandResetLifecycleListenerState
    extends State<CommandResetLifecycleListener>
    with WidgetsBindingObserver {
  bool _didRunInitialCheck = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didRunInitialCheck) return;
    _didRunInitialCheck = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_runInitialResetWithFeedback());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (!mounted) return;
    final provider = context.read<CommandProvider>();
    if (provider.commands.any((command) => command.pauses.isNotEmpty)) {
      provider.refreshAfterPause();
    } else {
      unawaited(provider.applyPendingAutoResetsSilently());
    }
  }

  Future<void> _runInitialResetWithFeedback() async {
    final report = await context
        .read<CommandProvider>()
        .applyPendingAutoResetsSilently();
    if (!mounted || !report.hasResets) return;
    final message = _buildMessage(report.byFrequency);
    if (message == null) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(message),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  String? _buildMessage(Map<Frequency, int> byFrequency) {
    if (byFrequency.isEmpty) return null;
    if (byFrequency.length == 1) {
      final entry = byFrequency.entries.first;
      final count = entry.value;
      final label = switch (entry.key) {
        Frequency.daily =>
          count > 1 ? context.l10n.quotidiens : context.l10n.quotidien2,
        Frequency.weekly =>
          count > 1 ? context.l10n.hebdomadaires : context.l10n.hebdomadaire2,
        Frequency.monthly =>
          count > 1 ? context.l10n.mensuels : context.l10n.mensuel2,
        Frequency.yearly =>
          count > 1 ? context.l10n.annuels : context.l10n.annuel2,
      };
      final noun = count > 1
          ? context.l10n.commandements2
          : context.l10n.commandement;
      return context.l10n.remisAZero2(count, noun, label);
    }
    final total = byFrequency.values.fold<int>(0, (sum, v) => sum + v);
    final noun = total > 1
        ? context.l10n.commandements2
        : context.l10n.commandement;
    return context.l10n.remisAZero(total, noun);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
