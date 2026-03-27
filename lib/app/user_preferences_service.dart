import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'theme_service.dart';

class UserPreferencesService {
  final FirebaseFirestore _firestore;
  final ThemeService _themeService;

  UserPreferencesService({
    FirebaseFirestore? firestore,
    required ThemeService themeService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _themeService = themeService;

  Future<void> syncThemeFromRemote({
    required String? uid,
  }) async {
    if (uid == null || uid.isEmpty) return;
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('preferences')
          .get();
      final data = snapshot.data();
      final remote = data?['theme'];
      if (remote is! String) return;
      await _themeService.applyThemeModeFromStorageValue(remote);
    } catch (_) {
      // En cas d'échec réseau, on conserve la préférence locale.
    }
  }

  Future<void> saveThemeToRemoteIfConnected({
    required String? uid,
    required ThemeMode mode,
  }) async {
    if (uid == null || uid.isEmpty) return;
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('preferences')
          .set(
        <String, dynamic>{
          'theme': _themeService.toStorageValue(mode),
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // La préférence locale est déjà persistée.
    }
  }
}
