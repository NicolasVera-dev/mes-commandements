import 'package:meta/meta.dart';

@immutable
class AuthUser {
  final String uid;
  final String? email;

  const AuthUser({
    required this.uid,
    required this.email,
  });

  @override
  bool operator ==(Object other) {
    return other is AuthUser && other.uid == uid && other.email == email;
  }

  @override
  int get hashCode => Object.hash(uid, email);
}

