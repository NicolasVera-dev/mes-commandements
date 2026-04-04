import 'package:flutter/material.dart';

import '../pages/login_page.dart';
import '../pages/onboarding_welcome_page.dart';

/// Flux hors-ligne : onboarding puis connexion sur une pile dédiée (sans persistance).
class UnauthenticatedFlow extends StatefulWidget {
  const UnauthenticatedFlow({super.key});

  @override
  State<UnauthenticatedFlow> createState() => _UnauthenticatedFlowState();
}

class _UnauthenticatedFlowState extends State<UnauthenticatedFlow> {
  var _loginOpen = false;

  void _openLogin() {
    setState(() => _loginOpen = true);
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      pages: <Page<void>>[
        MaterialPage<void>(
          key: const ValueKey<String>('onboarding'),
          name: 'onboarding',
          child: OnboardingWelcomePage(onCommencer: _openLogin),
        ),
        if (_loginOpen)
          const MaterialPage<void>(
            key: ValueKey<String>('login'),
            name: 'login',
            child: LoginPage(),
          ),
      ],
      onDidRemovePage: (Page<Object?> page) {
        if (page.key == const ValueKey<String>('login')) {
          setState(() => _loginOpen = false);
        }
      },
    );
  }
}
