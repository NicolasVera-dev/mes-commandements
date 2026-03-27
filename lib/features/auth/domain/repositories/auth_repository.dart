import 'dart:async';

import '../entities/auth_user.dart';

/// Contrat de la couche d'accès aux données d'authentification.
abstract class AuthRepository {
  /// État de connexion en temps réel.
  Stream<AuthUser?> authStateChanges();

  Future<AuthUser> signUp({
    required String email,
    required String password,
  });

  Future<AuthUser> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<void> sendPasswordResetEmail({
    required String email,
  });

  /// Nécessite que l'utilisateur soit connecté.
  /// La suppression/modification peut nécessiter une reconnexion récente selon Firebase.
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Nécessite que l'utilisateur soit connecté.
  /// Requiert généralement une reconnexion récente (currentPassword).
  Future<void> deleteAccount({
    required String currentPassword,
  });
}

