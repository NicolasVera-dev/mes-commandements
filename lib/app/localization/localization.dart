import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';

export '../../l10n/app_localizations.dart';
export 'system_messages.dart';

export 'package:flutter/widgets.dart' show Locale;

extension AppLocalizationContext on BuildContext {
  // Widgets rendered in isolated tests keep the historical French default.
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      lookupAppLocalizations(const Locale('fr'));
}
