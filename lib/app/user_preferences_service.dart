import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'command_card_display_mode.dart';
import 'command_card_layout_service.dart';
import 'theme_service.dart';

class UserPreferencesService {
  final FirebaseFirestore _firestore;
  final ThemeService _themeService;
  final CommandCardLayoutService _commandCardLayoutService;

  UserPreferencesService({
    FirebaseFirestore? firestore,
    required ThemeService themeService,
    required CommandCardLayoutService commandCardLayoutService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _themeService = themeService,
        _commandCardLayoutService = commandCardLayoutService;

  /// Synchronise thème et affichage des cartes depuis Firestore (une lecture).
  Future<void> syncUserPreferencesFromRemote({
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
      final remoteTheme = data?['theme'];
      if (remoteTheme is String) {
        await _themeService.applyThemeModeFromStorageValue(remoteTheme);
      }
      final remoteCard = data?['commandCardDisplay'];
      if (remoteCard is String) {
        await _commandCardLayoutService.applyFromStorageValue(remoteCard);
      }
    } catch (_) {
      // En cas d'échec réseau, on conserve les préférences locales.
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

  Future<void> saveCommandCardDisplayToRemoteIfConnected({
    required String? uid,
    required CommandCardDisplayMode mode,
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
          'commandCardDisplay': _commandCardLayoutService.toStorageValue(mode),
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // La préférence locale est déjà persistée.
    }
  }
}
