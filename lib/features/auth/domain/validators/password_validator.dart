// Validateur de mot de passe (logique pure, indépendant de l'UI).
//
// Règles applicables (voir l'exigence utilisateur) :
// - Minimum 12 caractères
// - Au moins une lettre majuscule
// - Au moins une lettre minuscule
// - Au moins un chiffre
// - Au moins un caractère spécial parmi : ! @ # $ % ^ & * ( ) , . ? : | < >
// - Pas d'espaces autorisés
// - Pas de répétition de plus de 2 caractères identiques consécutifs (aaa interdit)

enum PasswordStrength {
  faible,
  moyen,
  fort,
  tresFort,
}

enum PasswordRuleId {
  longueurMin,
  majuscule,
  minuscule,
  chiffre,
  special,
  sansEspaces,
  repetitionMax2,
}

class PasswordRuleStatus {
  final PasswordRuleId id;
  final String label;
  final bool isValid;
  final String? errorMessage;

  const PasswordRuleStatus({
    required this.id,
    required this.label,
    required this.isValid,
    this.errorMessage,
  });
}

class PasswordValidationResult {
  final List<PasswordRuleStatus> rules;
  final PasswordStrength strength;

  const PasswordValidationResult({
    required this.rules,
    required this.strength,
  });

  int get satisfiedRulesCount => rules.where((r) => r.isValid).length;

  /// Messages d'erreur uniquement pour les règles non respectées.
  List<String> get errorMessages =>
      rules.where((r) => !r.isValid).map((r) => r.errorMessage ?? '').where((m) => m.isNotEmpty).toList();

  String get strengthLabel {
    return switch (strength) {
      PasswordStrength.faible => 'Faible',
      PasswordStrength.moyen => 'Moyen',
      PasswordStrength.fort => 'Fort',
      PasswordStrength.tresFort => 'Très fort',
    };
  }
}

class PasswordValidator {
  static const int minLength = 12;
  static const int maxConsecutiveIdentical = 2;

  static const Set<String> _specialChars = <String>{
    '!',
    '@',
    '#',
    '\$',
    '%',
    '^',
    '&',
    '*',
    '(',
    ')',
    ',',
    '.',
    '?',
    ':',
    '|',
    '<',
    '>',
  };

  static PasswordValidationResult validate(String password) {
    final rules = <PasswordRuleStatus>[
      _validateLength(password),
      _validateUppercase(password),
      _validateLowercase(password),
      _validateDigit(password),
      _validateSpecial(password),
      _validateNoSpaces(password),
      _validateNoTooMuchConsecutiveRepetition(password),
    ];

    final satisfied = rules.where((r) => r.isValid).length;
    final strength = _strengthFromSatisfiedCount(satisfied, rules.length);

    return PasswordValidationResult(
      rules: rules,
      strength: strength,
    );
  }

  static PasswordStrength _strengthFromSatisfiedCount(
    int satisfied,
    int total,
  ) {
    // 7 règles au total : on mappe en 4 niveaux.
    // - 0-2 : Faible
    // - 3-4 : Moyen
    // - 5-6 : Fort
    // - 7   : Très fort
    if (satisfied <= 2) return PasswordStrength.faible;
    if (satisfied <= 4) return PasswordStrength.moyen;
    if (satisfied <= total - 1) return PasswordStrength.fort;
    return PasswordStrength.tresFort;
  }

  static PasswordRuleStatus _validateLength(String password) {
    final ok = password.length >= minLength;
    return PasswordRuleStatus(
      id: PasswordRuleId.longueurMin,
      label: '12 caractères minimum',
      isValid: ok,
      errorMessage:
          ok ? null : 'Le mot de passe doit contenir au moins 12 caractères.',
    );
  }

  static PasswordRuleStatus _validateUppercase(String password) {
    final ok = RegExp(r'[A-Z]').hasMatch(password);
    return PasswordRuleStatus(
      id: PasswordRuleId.majuscule,
      label: 'Au moins une majuscule',
      isValid: ok,
      errorMessage:
          ok ? null : 'Le mot de passe doit contenir au moins une lettre majuscule.',
    );
  }

  static PasswordRuleStatus _validateLowercase(String password) {
    final ok = RegExp(r'[a-z]').hasMatch(password);
    return PasswordRuleStatus(
      id: PasswordRuleId.minuscule,
      label: 'Au moins une minuscule',
      isValid: ok,
      errorMessage:
          ok ? null : 'Le mot de passe doit contenir au moins une lettre minuscule.',
    );
  }

  static PasswordRuleStatus _validateDigit(String password) {
    final ok = RegExp(r'[0-9]').hasMatch(password);
    return PasswordRuleStatus(
      id: PasswordRuleId.chiffre,
      label: 'Au moins un chiffre',
      isValid: ok,
      errorMessage:
          ok ? null : 'Le mot de passe doit contenir au moins un chiffre.',
    );
  }

  static PasswordRuleStatus _validateSpecial(String password) {
    final ok = password.split('').any(_specialChars.contains);
    return PasswordRuleStatus(
      id: PasswordRuleId.special,
      label: 'Au moins un caractère spécial',
      isValid: ok,
      errorMessage:
          ok
              ? null
              : 'Le mot de passe doit contenir au moins un caractère spécial parmi : ! @ # \$ % ^ & * ( ) , . ? : | < >',
    );
  }

  static PasswordRuleStatus _validateNoSpaces(String password) {
    final ok = !RegExp(r'\s').hasMatch(password);
    return PasswordRuleStatus(
      id: PasswordRuleId.sansEspaces,
      label: 'Sans espace',
      isValid: ok,
      errorMessage: ok ? null : 'Les espaces ne sont pas autorisés dans le mot de passe.',
    );
  }

  static PasswordRuleStatus _validateNoTooMuchConsecutiveRepetition(
    String password,
  ) {
    if (password.isEmpty) {
      return const PasswordRuleStatus(
        id: PasswordRuleId.repetitionMax2,
        label: 'Pas de répétition de plus de 2',
        isValid: false,
        errorMessage:
            'Le mot de passe ne doit pas contenir plus de 2 caractères identiques consécutifs.',
      );
    }

    var runLength = 1;
    for (var i = 1; i < password.length; i++) {
      final prev = password[i - 1];
      final current = password[i];
      if (current == prev) {
        runLength++;
        if (runLength > maxConsecutiveIdentical) {
          return PasswordRuleStatus(
            id: PasswordRuleId.repetitionMax2,
            label: 'Pas de répétition de plus de 2',
            isValid: false,
            errorMessage:
                'Le mot de passe ne doit pas contenir plus de 2 caractères identiques consécutifs.',
          );
        }
      } else {
        runLength = 1;
      }
    }

    return const PasswordRuleStatus(
      id: PasswordRuleId.repetitionMax2,
      label: 'Pas de répétition de plus de 2',
      isValid: true,
      errorMessage: null,
    );
  }
}

