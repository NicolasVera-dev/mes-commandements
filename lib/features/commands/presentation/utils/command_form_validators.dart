import '../../../../app/localization/localization.dart';

int? parsePositiveInt(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return null;
  final parsed = int.tryParse(value);
  if (parsed == null || parsed <= 0) return null;
  return parsed;
}

String? validateRequiredPositiveInt(
  String? value, {
  AppLocalizations? strings,
}) {
  final l10n = strings ?? lookupAppLocalizations(const Locale('fr'));

  final raw = (value ?? '').trim();
  if (raw.isEmpty) {
    return l10n.ceChampEstObligatoire;
  }
  final parsed = int.tryParse(raw);
  if (parsed == null || parsed <= 0) {
    return l10n.veuillezEntrerUnNombreValide;
  }
  return null;
}

int? parseNonNegativeInt(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return null;
  final parsed = int.tryParse(value);
  if (parsed == null || parsed < 0) return null;
  return parsed;
}
