import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/auth_user.dart';
import '../../domain/errors/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<AuthUser?> authStateChanges() {
    return _auth.authStateChanges().map((user) {
      if (user == null) return null;
      return AuthUser(uid: user.uid, email: user.email);
    });
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapAuthCodeToFrenchMessage(e.code));
    } catch (_) {
      throw const AuthFailure("Une erreur est survenue. Veuillez réessayer.");
    }
  }

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapAuthCodeToFrenchMessage(e.code));
    } catch (_) {
      throw const AuthFailure("Une erreur est survenue. Veuillez réessayer.");
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapAuthCodeToFrenchMessage(e.code));
    } catch (_) {
      throw const AuthFailure("Une erreur est survenue. Veuillez réessayer.");
    }
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapAuthCodeToFrenchMessage(e.code));
    } catch (_) {
      throw const AuthFailure("Une erreur est survenue. Veuillez réessayer.");
    }
  }

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthFailure("Veuillez vous connecter avant de modifier le mot de passe.");
    }

    try {
      // Re-connexion récente pour éviter "requires-recent-login".
      final email = user.email;
      if (email == null) {
        throw const AuthFailure('Impossible de modifier le mot de passe pour cet utilisateur.');
      }

      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapAuthCodeToFrenchMessage(e.code));
    } catch (_) {
      throw const AuthFailure("Une erreur est survenue. Veuillez réessayer.");
    }
  }

  @override
  Future<void> deleteAccount({
    required String currentPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthFailure("Veuillez vous connecter avant de supprimer le compte.");
    }

    try {
      final email = user.email;
      if (email == null) {
        throw const AuthFailure('Impossible de supprimer le compte pour cet utilisateur.');
      }

      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await _deleteAllUserCommandsAndEvents(uid: user.uid);
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapAuthCodeToFrenchMessage(e.code));
    } on StateError catch (e) {
      throw AuthFailure(e.message);
    } catch (_) {
      throw const AuthFailure("Une erreur est survenue. Veuillez réessayer.");
    }
  }

  Future<void> _deleteAllUserCommandsAndEvents({
    required String uid,
  }) async {
    final commandsCollection = _firestore.collection('users/$uid/commands');
    final commandsSnapshot = await commandsCollection.get();
    if (commandsSnapshot.docs.isEmpty) return;

    const maxBatchOps = 500;

    for (final commandDoc in commandsSnapshot.docs) {
      final eventsSnapshot = await commandDoc.reference.collection('events').get();
      final eventDocs = eventsSnapshot.docs;

      var cursor = 0;
      while (cursor < eventDocs.length) {
        final availableForEvents = maxBatchOps - 1;
        final end = (cursor + availableForEvents > eventDocs.length)
            ? eventDocs.length
            : cursor + availableForEvents;

        final batch = _firestore.batch();
        for (var i = cursor; i < end; i++) {
          batch.delete(eventDocs[i].reference);
        }

        if (end == eventDocs.length) {
          batch.delete(commandDoc.reference);
        }

        await batch.commit();
        cursor = end;
      }

      if (eventDocs.isEmpty) {
        await commandDoc.reference.delete();
      }
    }
  }

  String _mapAuthCodeToFrenchMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Cette adresse email est déjà utilisée.';
      case 'invalid-email':
        return 'L\'adresse email n\'est pas valide.';
      case 'weak-password':
        return 'Le mot de passe est trop faible ou trop court.';
      case 'operation-not-allowed':
        return 'L\'inscription avec email et mot de passe n\'est pas autorisée.';
      case 'user-disabled':
        return 'Cet utilisateur a été désactivé.';
      case 'user-not-found':
        return 'Utilisateur introuvable.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'invalid-credential':
        return 'Identifiants invalides.';
      case 'requires-recent-login':
        return 'Veuillez vous reconnecter avant de modifier le mot de passe ou de supprimer le compte.';
      case 'too-many-requests':
        return 'Trop de tentatives. Veuillez réessayer plus tard.';
      case 'network-request-failed':
        return 'Vérifiez votre connexion internet puis réessayez.';
      default:
        return 'Une erreur est survenue lors de l\'authentification. Veuillez réessayer.';
    }
  }
}

