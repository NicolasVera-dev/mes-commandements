import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/widgets/dismiss_keyboard_on_tap.dart';
import '../../../../app/command_card_display_mode.dart';
import '../../../../app/command_card_layout_service.dart';
import '../../../../app/theme_service.dart';
import '../../../../app/user_preferences_service.dart';
import '../../../notifications/presentation/widgets/notification_settings_card.dart';
import '../state/auth_provider.dart';
import '../widgets/password_strength_indicator.dart';
import '../widgets/password_text_field.dart';
import '../../domain/validators/password_validator.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  bool _isUpdatingPassword = false;
  String? _updatePasswordError;
  bool _isSigningOut = false;
  String? _signOutError;

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();

  PasswordValidationResult _newPasswordResult =
      PasswordValidator.validate('');

  bool get _passwordsMatch =>
      _newPasswordController.text == _confirmNewPasswordController.text &&
      _confirmNewPasswordController.text.isNotEmpty;

  bool get _allRulesSatisfied =>
      _newPasswordResult.rules.every((r) => r.isValid);

  bool get _canUpdatePassword {
    return !_isUpdatingPassword &&
        _currentPasswordController.text.isNotEmpty &&
        _allRulesSatisfied &&
        _passwordsMatch;
  }

  bool _isDeleting = false;
  String? _deleteError;

  final _deletePasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(() {
      setState(() => _newPasswordResult =
          PasswordValidator.validate(_newPasswordController.text));
      if (_updatePasswordError != null && _canUpdatePassword) {
        setState(() => _updatePasswordError = null);
      }
    });
    _confirmNewPasswordController.addListener(() {
      if (_updatePasswordError != null && _canUpdatePassword) {
        setState(() => _updatePasswordError = null);
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    _deletePasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    setState(() {
      _isUpdatingPassword = true;
      _updatePasswordError = null;
    });

    final auth = context.read<AuthProvider>();
    try {
      await auth.updatePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      if (!mounted) return;
      setState(() => _updatePasswordError = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe mis à jour.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _updatePasswordError = auth.errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isUpdatingPassword = false);
      }
    }
  }

  Future<void> _deleteAccount() async {
    final auth = context.read<AuthProvider>();

    if (_deletePasswordController.text.isEmpty) {
      setState(() => _deleteError = 'Ce champ est obligatoire');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Supprimer le compte ?'),
          content: const Text(
            'Cette action est irréversible. Confirmez la suppression.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _isDeleting = true;
      _deleteError = null;
    });

    try {
      await auth.deleteAccount(currentPassword: _deletePasswordController.text);
    } catch (_) {
      if (!mounted) return;
      setState(() => _deleteError = auth.errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  Future<void> _signOut() async {
    final auth = context.read<AuthProvider>();
    setState(() {
      _isSigningOut = true;
      _signOutError = null;
    });

    try {
      await auth.signOut();
    } catch (_) {
      if (!mounted) return;
      setState(() => _signOutError = auth.errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isSigningOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeService = context.watch<ThemeService>();
    final cardLayoutService = context.watch<CommandCardLayoutService>();
    final userPreferencesService = context.read<UserPreferencesService>();
    final currentThemeMode = themeService.themeMode;
    final currentCardMode = cardLayoutService.displayMode;

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
      // AuthGate bascule sur UnauthenticatedFlow ; pas de LoginPage ici.
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres du compte'),
      ),
      body: DismissKeyboardOnTap(
        child: SafeArea(
          child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: 16,
          ),
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              Text(
                'Utilisateur connecté${auth.user?.email != null ? ' : ${auth.user!.email}' : ''}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 18),
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Apparence',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      RadioGroup<ThemeMode>(
                        groupValue: currentThemeMode,
                        onChanged: (next) {
                          if (_isUpdatingPassword || _isDeleting || _isSigningOut) {
                            return;
                          }
                          if (next == null) return;
                          unawaited(themeService.setThemeMode(next));
                          unawaited(
                            userPreferencesService.saveThemeToRemoteIfConnected(
                              uid: auth.user?.uid,
                              mode: next,
                            ),
                          );
                        },
                        child: Column(
                          children: const [
                            RadioListTile<ThemeMode>(
                              value: ThemeMode.dark,
                              title: Text('Sombre'),
                              secondary: Icon(Icons.dark_mode_rounded),
                              contentPadding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                            RadioListTile<ThemeMode>(
                              value: ThemeMode.light,
                              title: Text('Clair'),
                              secondary: Icon(Icons.light_mode_rounded),
                              contentPadding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                            RadioListTile<ThemeMode>(
                              value: ThemeMode.system,
                              title: Text('Automatique'),
                              secondary: Icon(Icons.sync_rounded),
                              contentPadding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Affichage des cartes',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      RadioGroup<CommandCardDisplayMode>(
                        groupValue: currentCardMode,
                        onChanged: (next) {
                          if (_isUpdatingPassword ||
                              _isDeleting ||
                              _isSigningOut) {
                            return;
                          }
                          if (next == null) return;
                          unawaited(cardLayoutService.setDisplayMode(next));
                          unawaited(
                            userPreferencesService
                                .saveCommandCardDisplayToRemoteIfConnected(
                              uid: auth.user?.uid,
                              mode: next,
                            ),
                          );
                        },
                        child: Column(
                          children: const [
                            RadioListTile<CommandCardDisplayMode>(
                              value: CommandCardDisplayMode.standard,
                              title: Text('Standard'),
                              subtitle: Text(
                                'Commandements et résistances — détail par défaut',
                              ),
                              secondary: Icon(Icons.view_agenda_outlined),
                              contentPadding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                            RadioListTile<CommandCardDisplayMode>(
                              value: CommandCardDisplayMode.compact,
                              title: Text('Compact'),
                              subtitle: Text(
                                'Commandements et résistances — liste plus dense',
                              ),
                              secondary: Icon(Icons.view_headline_rounded),
                              contentPadding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const NotificationSettingsCard(),
              const SizedBox(height: 18),
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Modification du mot de passe',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      PasswordTextField(
                        controller: _currentPasswordController,
                        enabled: !_isUpdatingPassword,
                        labelText: 'Mot de passe actuel',
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      PasswordTextField(
                        controller: _newPasswordController,
                        enabled: !_isUpdatingPassword,
                        labelText: 'Nouveau mot de passe',
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 10),
                      PasswordStrengthIndicator(result: _newPasswordResult),
                      const SizedBox(height: 12),
                      PasswordTextField(
                        controller: _confirmNewPasswordController,
                        enabled: !_isUpdatingPassword,
                        labelText: 'Confirmer le nouveau mot de passe',
                        textInputAction: TextInputAction.done,
                      ),
                      if (_confirmNewPasswordController.text.isNotEmpty &&
                          !_passwordsMatch)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Les mots de passe ne correspondent pas.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                          ),
                        ),
                      if (_updatePasswordError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            _updatePasswordError!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                          ),
                        ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: _canUpdatePassword ? _updatePassword : null,
                          child: _isUpdatingPassword
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Mettre à jour'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Suppression du compte',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      PasswordTextField(
                        controller: _deletePasswordController,
                        enabled: !_isDeleting,
                        labelText: 'Mot de passe actuel',
                      ),
                      if (_deleteError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _deleteError!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                          ),
                        ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: _isDeleting ? null : _deleteAccount,
                          child: _isDeleting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Supprimer le compte'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_signOutError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _signOutError!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed:
                      _isUpdatingPassword || _isDeleting || _isSigningOut
                          ? null
                          : _signOut,
                  icon: const Icon(Icons.logout_rounded),
                  label: _isSigningOut
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Se déconnecter'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isUpdatingPassword || _isDeleting || _isSigningOut
                    ? null
                    : () {
                        Navigator.of(context).maybePop();
                      },
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

