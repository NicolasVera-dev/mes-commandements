import 'package:flutter/material.dart';

/// Couleur du streak : orange vif → vert au fil des jours (plafonné).
Color resistanceStreakColor({
  required int streakDays,
  required BuildContext context,
}) {
  final scheme = Theme.of(context).colorScheme;
  final warm = Color.lerp(scheme.tertiary, Colors.deepOrange, 0.55)!;
  final cool = Color.lerp(scheme.primary, const Color(0xFF2E7D32), 0.35)!;
  final t = (streakDays / 28.0).clamp(0.0, 1.0);
  final curved = Curves.easeOut.transform(t);
  return Color.lerp(warm, cool, curved)!;
}
