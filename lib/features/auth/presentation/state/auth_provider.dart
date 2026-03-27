import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/auth_user.dart';
import '../../domain/errors/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';

enum AuthStatus {
  enChargement,
  connecte,
  deconnecte,
  erreur,
}

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;
  late final StreamSubscription<AuthUser?> _subscription;
  late final Stream<AuthUser?> _authStream;

  AuthUser? _user;
  String? _errorMessage;
  bool _isInitialLoading = true;
  bool _hasReceivedFirstAuthEvent = false;
  AuthStatus _status = AuthStatus.enChargement;

  AuthProvider({
    required AuthRepository repository,
  }) : _repository = repository {
    _authStream = _repository.authStateChanges();

    _subscription = _authStream.listen(
      (user) {
        _user = user;
        _errorMessage = null;
        _hasReceivedFirstAuthEvent = true;
        _isInitialLoading = false;
        _status = user == null ? AuthStatus.deconnecte : AuthStatus.connecte;
        notifyListeners();
      },
      onError: (Object error, StackTrace st) {
        debugPrint('Erreur auth stream: $error');
        debugPrint('$st');
        _errorMessage = 'Une erreur est survenue. Veuillez réessayer.';
        _hasReceivedFirstAuthEvent = true;
        _isInitialLoading = false;
        _status = AuthStatus.erreur;
        notifyListeners();
      },
    );
  }

  Stream<AuthUser?> get authStateChanges => _authStream;

  AuthUser? get user => _user;

  AuthStatus get status => _status;
  bool get isInitialLoading => _isInitialLoading;
  bool get isConnected => _user != null;

  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    // On conserve le statut actuel si l'utilisateur est déjà connu,
    // sinon on revient à l'état initial.
    if (!_hasReceivedFirstAuthEvent) {
      _status = AuthStatus.enChargement;
      _isInitialLoading = true;
    } else {
      _status = _user == null ? AuthStatus.deconnecte : AuthStatus.connecte;
    }
    notifyListeners();
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    clearError();
    try {
      final user = await _repository.signUp(email: email, password: password);
      _user = user;
      _hasReceivedFirstAuthEvent = true;
      _isInitialLoading = false;
      _status = AuthStatus.connecte;
      notifyListeners();
    } on AuthFailure catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    clearError();
    try {
      final user = await _repository.signIn(email: email, password: password);
      _user = user;
      _hasReceivedFirstAuthEvent = true;
      _isInitialLoading = false;
      _status = AuthStatus.connecte;
      notifyListeners();
    } on AuthFailure catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    clearError();
    try {
      await _repository.signOut();
    } on AuthFailure catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    clearError();
    try {
      await _repository.sendPasswordResetEmail(email: email);
    } on AuthFailure catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    clearError();
    try {
      await _repository.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } on AuthFailure catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteAccount({
    required String currentPassword,
  }) async {
    clearError();
    try {
      await _repository.deleteAccount(currentPassword: currentPassword);
    } on AuthFailure catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

