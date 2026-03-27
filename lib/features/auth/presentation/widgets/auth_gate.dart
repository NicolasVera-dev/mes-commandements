import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_provider.dart';
import '../pages/login_page.dart';

class AuthGate extends StatelessWidget {
  final Widget authenticatedChild;

  const AuthGate({
    super.key,
    required this.authenticatedChild,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pages = <Page<void>>[
      if (auth.isInitialLoading)
        const MaterialPage<void>(
          key: ValueKey<String>('auth-loading'),
          child: _AuthLoadingPage(),
        )
      else if (!auth.isConnected)
        const MaterialPage<void>(
          key: ValueKey<String>('auth-login'),
          child: LoginPage(),
        )
      else
        MaterialPage<void>(
          key: const ValueKey<String>('auth-home'),
          child: authenticatedChild,
        ),
    ];

    return Navigator(
      pages: pages,
      onPopPage: (route, result) {
        if (!route.didPop(result)) {
          return false;
        }
        return true;
      },
    );
  }
}

class _AuthLoadingPage extends StatelessWidget {
  const _AuthLoadingPage();

  @override
  Widget build(BuildContext context) {
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
}

