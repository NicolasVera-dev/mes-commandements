int? parsePositiveInt(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return null;
  final parsed = int.tryParse(value);
  if (parsed == null || parsed <= 0) return null;
  return parsed;
}

String? validateRequiredPositiveInt(String? value) {
  final raw = (value ?? '').trim();
  if (raw.isEmpty) {
    return 'Ce champ est obligatoire';
  }
  final parsed = int.tryParse(raw);
  if (parsed == null || parsed <= 0) {
    return 'Veuillez entrer un nombre valide';
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

