import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_provider.dart';
import '../../presentation/pages/login_page.dart';

class RequireAuth extends StatelessWidget {
  final Widget child;

  const RequireAuth({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isInitialLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(
                'Vérification de la session...',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    if (!auth.isConnected) {
      return const LoginPage();
    }

    return child;
  }
}

