import 'cycle_visual_style.dart';
import '../../../../app/localization/localization.dart';

/// Libellé court français pour un [cycleKey] (titre de feuille / dialogue).
String cycleKeyDisplayLabel(String cycleKey, {AppLocalizations? strings}) {
  final l10n = strings ?? lookupAppLocalizations(const Locale('fr'));

  final daily = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(cycleKey);
  if (daily != null) {
    final y = int.parse(daily.group(1)!);
    final m = int.parse(daily.group(2)!);
    final d = int.parse(daily.group(3)!);
    return '$d ${monthLabel(m, strings: l10n)} $y';
  }

  final weekly = RegExp(r'^(\d{4})-[SW](\d{2})$').firstMatch(cycleKey);
  if (weekly != null) {
    final y = weekly.group(1)!;
    final w = weekly.group(2)!;
    return l10n.semaine(w, y);
  }

  final monthly = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(cycleKey);
  if (monthly != null) {
    final y = int.parse(monthly.group(1)!);
    final m = int.parse(monthly.group(2)!);
    return '${monthLabel(m, strings: l10n)} $y';
  }

  final yearly = RegExp(r'^(\d{4})$').firstMatch(cycleKey);
  if (yearly != null) {
    return l10n.annee(yearly.group(1)!);
  }

  return cycleKey;
}
