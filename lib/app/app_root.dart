import 'package:flutter/material.dart';

import '../features/auth/presentation/widgets/auth_gate.dart';
import '../features/counter/presentation/pages/home_page.dart';
import '../features/counter/presentation/widgets/command_reset_lifecycle_listener.dart';

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return const CommandResetLifecycleListener(
      child: AuthGate(
        authenticatedChild: HomePage(),
      ),
    );
  }
}
