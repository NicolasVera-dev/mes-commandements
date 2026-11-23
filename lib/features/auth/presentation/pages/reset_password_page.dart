import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/widgets/dismiss_keyboard_on_tap.dart';
import '../state/auth_provider.dart';
import '../widgets/fade_scale_page_route.dart';
import 'login_page.dart';
import '../../../../app/localization/localization.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _emailFocus = FocusNode();

  bool _isSubmitting = false;
  String? _errorMessage;
  bool _sent = false;

  @override
  void dispose() {
    _emailFocus.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool _isEmailValid(String email) {
    final value = email.trim();
    if (value.isEmpty) return false;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;

    final auth = context.read<AuthProvider>();
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await auth.sendPasswordResetEmail(email: _emailController.text.trim());
      if (!mounted) return;
      setState(() => _sent = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = auth.errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

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
                context.l10n.verificationDeLaSession,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }
    if (auth.isConnected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.reinitialisationDuMotDePasse)),
      body: DismissKeyboardOnTap(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 16),
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    Text(
                      context.l10n.entrezVotreEmail,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _emailController,
                      focusNode: _emailFocus,
                      enabled: !_isSubmitting,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autofillHints: const <String>[
                        AutofillHints.username,
                        AutofillHints.email,
                      ],
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: context.l10n.email,
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.isEmpty)
                          return context.l10n.ceChampEstObligatoire;
                        if (!_isEmailValid(v))
                          return context
                              .l10n
                              .veuillezEntrerUneAdresseEmailValide;
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    if (_errorMessage != null) ...[
                      Text(
                        context.l10n.systemMessage(_errorMessage!),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (_sent)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          context
                              .l10n
                              .unEmailDeReinitialisationAEteEnvoyeSiLadresse,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: _isSubmitting || _sent ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(context.l10n.envoyerLemail),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              Navigator.of(context).push(
                                FadeScalePageRoute(
                                  pageBuilder: (_) => const LoginPage(),
                                ),
                              );
                            },
                      child: Text(context.l10n.retourALaConnexion),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
