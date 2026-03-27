import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/fade_scale_page_route.dart';
import '../widgets/password_text_field.dart';
import '../state/auth_provider.dart';
import 'reset_password_page.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onFieldsChanged);
    _passwordController.addListener(_onFieldsChanged);
  }

  void _onFieldsChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _emailController.removeListener(_onFieldsChanged);
    _passwordController.removeListener(_onFieldsChanged);
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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
    setState(() => _isSubmitting = true);
    setState(() => _errorMessage = null);

    try {
      await auth.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
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
    final canSubmit = !_isSubmitting &&
        _isEmailValid(_emailController.text) &&
        _passwordController.text.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion'),
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
                  'Retrouvez vos commandements',
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
                    if (!_isEmailValid(v)) return 'Veuillez entrer une adresse email valide';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                PasswordTextField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  enabled: !_isSubmitting,
                  labelText: 'Mot de passe',
                  textInputAction: TextInputAction.done,
                  autofillHints: const <String>[AutofillHints.password],
                  onFieldSubmitted: (_) => _submit(),
                  errorText: _errorMessage,
                  onChanged: (_) {
                    if (_errorMessage != null) {
                      setState(() => _errorMessage = null);
                    }
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: canSubmit ? _submit : null,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Se connecter'),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          Navigator.of(context).push(
                            FadeScalePageRoute(
                              pageBuilder: (_) => const SignUpPage(),
                            ),
                          );
                        },
                  child: const Text('Créer un compte'),
                ),
                TextButton(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          Navigator.of(context).push(
                            FadeScalePageRoute(
                              pageBuilder: (_) =>
                                  const ResetPasswordPage(),
                            ),
                          );
                        },
                  child: const Text('Mot de passe oublié'),
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
