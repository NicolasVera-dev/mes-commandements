import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rituel/app/localization/language_service.dart';
import 'package:rituel/app/localization/language_settings_card.dart';
import 'package:rituel/app/localization/localization.dart';
import 'package:rituel/features/commands/presentation/utils/cycle_key_display_label.dart';
import 'package:rituel/features/commands/presentation/widgets/command_streak_badge.dart';
import 'package:rituel/features/commands/domain/entities/command.dart';
import 'package:rituel/features/commands/domain/usecases/compute_streak_usecase.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('French is the default, including unknown saved languages', () async {
    for (final saved in [null, 'invalid', 'fr']) {
      SharedPreferences.setMockInitialValues({
        if (saved != null) 'app.language': saved,
      });
      final preferences = await SharedPreferences.getInstance();
      final service = LanguageService(preferences: preferences);
      expect(service.locale.languageCode, 'fr');
      service.dispose();
    }
  });

  test(
    'language survives a new service instance and can return to French',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final first = LanguageService(preferences: preferences);
      await first.setLanguage('en');
      final restarted = LanguageService(preferences: preferences);
      expect(restarted.locale.languageCode, 'en');
      await restarted.setLanguage('fr');
      expect(
        LanguageService(preferences: preferences).locale.languageCode,
        'fr',
      );
      await expectLater(first.setLanguage('de'), throwsArgumentError);
      first.dispose();
      restarted.dispose();
    },
  );

  testWidgets(
    'settings switch UI and native date labels without losing French',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final service = LanguageService(preferences: preferences);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: service,
          child: Builder(
            builder: (context) {
              final locale = context.watch<LanguageService>().locale;
              return MaterialApp(
                locale: locale,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Scaffold(
                  body: Builder(
                    builder: (context) => Column(
                      children: [
                        const LanguageSettingsCard(),
                        Text(context.l10n.mesCommandements),
                        Text(
                          MaterialLocalizations.of(context)
                              .formatFullDate(DateTime(2026, 11, 9)),
                        ),
                        const CommandStreakBadge(
                          result: StreakResult(
                            badge: StreakBadge.goodStart,
                            count: 2,
                          ),
                          frequency: Frequency.daily,
                          compact: false,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Mes commandements'), findsOneWidget);
      expect(find.text('Bon départ · 2 jours réussis'), findsOneWidget);
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(find.text('My commandments'), findsOneWidget);
      expect(find.text('Good start · 2 successful days'), findsOneWidget);
      expect(find.textContaining('November'), findsOneWidget);
      expect(
        LanguageService(preferences: preferences).locale.languageCode,
        'en',
      );
      await tester.tap(find.text('Français'));
      await tester.pumpAndSettle();
      expect(find.text('Mes commandements'), findsOneWidget);
      expect(find.textContaining('novembre'), findsOneWidget);
      service.dispose();
    },
  );

  test('dates, validation and template resources exist in both languages', () {
    final fr = lookupAppLocalizations(const Locale('fr'));
    final en = lookupAppLocalizations(const Locale('en'));
    expect(cycleKeyDisplayLabel('2026-11-09', strings: fr), '9 novembre 2026');
    expect(cycleKeyDisplayLabel('2026-11-09', strings: en), '9 November 2026');
    expect(en.systemMessage('Mot de passe incorrect.'), 'Incorrect password.');
    expect(en.systemMessage('Arrêter de fumer'), 'Quit smoking');
    expect(fr.systemMessage('Arrêter de fumer'), 'Arrêter de fumer');
  });
}
