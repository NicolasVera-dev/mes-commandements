import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/fade_scale_page_route.dart';
import '../widgets/password_strength_indicator.dart';
import '../widgets/password_text_field.dart';
import '../state/auth_provider.dart';
import '../../domain/validators/password_validator.dart';
import 'login_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _isSubmitting = false;
  String? _errorMessage;

  PasswordValidationResult _passwordResult =
      PasswordValidator.validate('');

  bool get _passwordsMatch =>
      _passwordController.text == _confirmController.text &&
      _confirmController.text.isNotEmpty;

  bool get _emailValid {
    final v = _emailController.text.trim();
    if (v.isEmpty) return false;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
  }

  bool get _allRulesSatisfied => _passwordResult.rules.every((r) => r.isValid);

  bool get _canSubmit {
    return !_isSubmitting &&
        _emailValid &&
        _allRulesSatisfied &&
        _passwordsMatch &&
        _passwordController.text.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
    _confirmController.addListener(() {
      if (_errorMessage != null && _passwordsMatch) {
        setState(() => _errorMessage = null);
      } else {
        setState(() {});
      }
    });
  }

  void _onPasswordChanged() {
    final next = PasswordValidator.validate(_passwordController.text);
    setState(() => _passwordResult = next);

    if (_errorMessage != null && _canSubmit) {
      setState(() => _errorMessage = null);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;

    if (!_allRulesSatisfied) {
      setState(() {
        _errorMessage = _passwordResult.errorMessages.isNotEmpty
            ? _passwordResult.errorMessages.first
            : 'Veuillez respecter toutes les règles du mot de passe.';
      });
      return;
    }

    if (_passwordController.text != _confirmController.text) {
      setState(() => _errorMessage = 'Les mots de passe ne correspondent pas.');
      return;
    }

    final auth = context.read<AuthProvider>();
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
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
                'Vérification de la session...',
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
      appBar: AppBar(
        title: const Text('Inscription'),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 16,
            ),
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                Text(
                  'Créez votre compte',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  enabled: !_isSubmitting,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const <String>[AutofillHints.username, AutofillHints.email],
                  onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return 'Ce champ est obligatoire';
                    if (!_emailValid) {
                      return 'Veuillez entrer une adresse email valide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                PasswordTextField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  enabled: !_isSubmitting,
                  labelText: 'Mot de passe',
                  textInputAction: TextInputAction.next,
                  autofillHints: const <String>[AutofillHints.newPassword],
                  onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
                  onChanged: (_) {
                    if (_errorMessage != null) setState(() => _errorMessage = null);
                  },
                ),
                const SizedBox(height: 10),
                PasswordStrengthIndicator(result: _passwordResult),
                const SizedBox(height: 12),
                PasswordTextField(
                  controller: _confirmController,
                  focusNode: _confirmFocus,
                  enabled: !_isSubmitting,
                  labelText: 'Confirmer le mot de passe',
                  textInputAction: TextInputAction.done,
                  autofillHints: const <String>[AutofillHints.newPassword],
                  onFieldSubmitted: (_) => _submit(),
                  onChanged: (_) {
                    if (_errorMessage != null) setState(() => _errorMessage = null);
                    setState(() {});
                  },
                ),
                if (_confirmController.text.isNotEmpty &&
                    _passwordController.text != _confirmController.text)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Les mots de passe ne correspondent pas.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                  ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _canSubmit ? _submit : null,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Créer le compte"),
                  ),
                ),
                const SizedBox(height: 12),
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
                  child: const Text('J’ai déjà un compte'),
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
