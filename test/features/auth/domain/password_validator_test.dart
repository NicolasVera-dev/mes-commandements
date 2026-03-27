import 'package:flutter_test/flutter_test.dart';
import 'package:mes_commandements/features/auth/domain/validators/password_validator.dart';

void main() {
  group('PasswordValidator', () {
    test('retourne Très fort quand toutes les règles sont satisfaites', () {
      final result = PasswordValidator.validate('Abcdef!23456');
      expect(result.rules.every((r) => r.isValid), isTrue);
      expect(result.strength, PasswordStrength.tresFort);
      expect(result.strengthLabel, 'Très fort');
      expect(result.errorMessages, isEmpty);
      expect(result.satisfiedRulesCount, 7);
    });

    test('retourne Faible pour un mot de passe vide', () {
      final result = PasswordValidator.validate('');
      expect(result.strength, PasswordStrength.faible);
      expect(result.satisfiedRulesCount, 1); // Sans espaces uniquement.
      expect(result.errorMessages, isNotEmpty);
    });

    test('détecte absence de majuscule', () {
      final result = PasswordValidator.validate('abcdef!23456');
      final rule = result.rules.firstWhere((r) => r.id == PasswordRuleId.majuscule);
      expect(rule.isValid, isFalse);
      expect(rule.errorMessage, isNotNull);
    });

    test('détecte absence de minuscule', () {
      final result = PasswordValidator.validate('ABCDEF!23456');
      final rule = result.rules.firstWhere((r) => r.id == PasswordRuleId.minuscule);
      expect(rule.isValid, isFalse);
    });

    test('détecte absence de chiffre', () {
      final result = PasswordValidator.validate('Abcdef!ghijk');
      final rule = result.rules.firstWhere((r) => r.id == PasswordRuleId.chiffre);
      expect(rule.isValid, isFalse);
    });

    test('détecte absence de caractère spécial', () {
      final result = PasswordValidator.validate('Abcdefgh1234');
      final rule = result.rules.firstWhere((r) => r.id == PasswordRuleId.special);
      expect(rule.isValid, isFalse);
    });

    test('détecte présence d espaces', () {
      final result = PasswordValidator.validate('Abcde f!23456');
      final rule = result.rules.firstWhere((r) => r.id == PasswordRuleId.sansEspaces);
      expect(rule.isValid, isFalse);
    });

    test('détecte répétition de plus de 2 caractères', () {
      final result = PasswordValidator.validate('Abc!!!def1234');
      final rule = result.rules.firstWhere((r) => r.id == PasswordRuleId.repetitionMax2);
      expect(rule.isValid, isFalse);
    });

    test('force est Moyen quand 3-4 règles satisfaites', () {
      final result = PasswordValidator.validate('abc');
      expect(result.satisfiedRulesCount, inInclusiveRange(3, 4));
      expect(result.strength, PasswordStrength.moyen);
      expect(result.strengthLabel, 'Moyen');
    });

    test('force est Fort quand 5-6 règles satisfaites', () {
      final result = PasswordValidator.validate('Abcdefgh1234');
      expect(result.satisfiedRulesCount, inInclusiveRange(5, 6));
      expect(result.strength, PasswordStrength.fort);
      expect(result.strengthLabel, 'Fort');
    });
  });
}
