import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/command.dart';
import '../state/command_provider.dart';

/// Déclenche le reset auto au lancement puis à chaque retour au premier plan.
class CommandResetLifecycleListener extends StatefulWidget {
  final Widget child;

  const CommandResetLifecycleListener({
    super.key,
    required this.child,
  });

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
    unawaited(
      context.read<CommandProvider>().applyPendingAutoResetsSilently(),
    );
  }

  Future<void> _runInitialResetWithFeedback() async {
    final report = await context.read<CommandProvider>().applyPendingAutoResetsSilently();
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
        Frequency.daily => count > 1 ? 'quotidiens' : 'quotidien',
        Frequency.weekly => count > 1 ? 'hebdomadaires' : 'hebdomadaire',
        Frequency.monthly => count > 1 ? 'mensuels' : 'mensuel',
        Frequency.yearly => count > 1 ? 'annuels' : 'annuel',
      };
      final noun = count > 1 ? 'commandements' : 'commandement';
      return '$count $noun $label remis à zéro';
    }
    final total = byFrequency.values.fold<int>(0, (sum, v) => sum + v);
    final noun = total > 1 ? 'commandements' : 'commandement';
    return '$total $noun remis à zéro';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
