import 'package:flutter_test/flutter_test.dart';
import 'package:rituel/features/auth/domain/entities/auth_user.dart';
import 'package:rituel/features/auth/domain/errors/auth_failure.dart';

void main() {
  group('AuthUser', () {
    test('égalité et hashCode cohérents', () {
      const a = AuthUser(uid: 'u1', email: 'a@b.c');
      const b = AuthUser(uid: 'u1', email: 'a@b.c');
      const c = AuthUser(uid: 'u2', email: 'a@b.c');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });
  });

  group('AuthFailure', () {
    test('toString inclut le message', () {
      const failure = AuthFailure('Erreur test');
      expect(failure.toString(), contains('Erreur test'));
    });
  });
}
