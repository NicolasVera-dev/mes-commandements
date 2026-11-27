import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rituel/app/app_theme.dart';
import 'package:rituel/app/localization/localization.dart';
import 'package:rituel/features/auth/presentation/pages/onboarding_welcome_page.dart';
import 'package:rituel/features/auth/presentation/widgets/onboarding/onboarding_brand_header.dart';

Future<void> mount(
  WidgetTester tester, {
  String locale = 'fr',
  bool active = true,
  bool reducedMotion = false,
  bool accessible = false,
  double textScale = 1,
  VoidCallback? start,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(locale),
      theme: AppTheme.lightTheme(),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: reducedMotion,
          accessibleNavigation: accessible,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: OnboardingWelcomePage(
        isActive: active,
        onCommencer: start ?? () {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

int pageIndex(WidgetTester tester) =>
    tester.widget<PageView>(find.byType(PageView)).controller!.page!.round() %
    4;
Future<void> next(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 8));
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'implicit eight-second rotation loops through four pages with fixed brand and original dots',
    (tester) async {
      await mount(tester);
      final header = tester.getTopLeft(find.byType(OnboardingBrandHeader));
      expect(pageIndex(tester), 0);
      expect(find.text('RITUEL'), findsOneWidget);
      expect(find.byType(IconButton), findsNothing);
      expect(find.byIcon(Icons.pause_rounded), findsNothing);
      expect(find.byIcon(Icons.replay_rounded), findsNothing);
      final dots = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .toList();
      expect(dots, hasLength(4));
      expect(dots.first.constraints!.maxWidth, 28);
      expect(dots[1].constraints!.maxWidth, 8);
      await tester.pump(const Duration(seconds: 7));
      expect(pageIndex(tester), 0);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(pageIndex(tester), 1);
      expect(tester.getTopLeft(find.byType(OnboardingBrandHeader)), header);
      await next(tester);
      expect(pageIndex(tester), 2);
      await next(tester);
      expect(pageIndex(tester), 3);
      expect(find.text('Savoure le travail accompli'), findsOneWidget);
      await next(tester);
      expect(pageIndex(tester), 0);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('manual swipe restarts the automatic eight-second delay', (
    tester,
  ) async {
    await mount(tester);
    await tester.pump(const Duration(seconds: 7));
    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(pageIndex(tester), 1);
    await tester.pump(const Duration(seconds: 4));
    expect(pageIndex(tester), 1);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(pageIndex(tester), 2);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('background and covered onboarding do not rotate', (
    tester,
  ) async {
    await mount(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 20));
    expect(pageIndex(tester), 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await next(tester);
    expect(pageIndex(tester), 1);
    await mount(tester, active: false);
    await tester.pump(const Duration(seconds: 20));
    expect(pageIndex(tester), 1);
    await mount(tester, active: true);
    await next(tester);
    expect(pageIndex(tester), 2);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  for (final reduce in [true, false]) {
    testWidgets('accessibility keeps manual swipes: reduced motion=$reduce', (
      tester,
    ) async {
      await mount(tester, reducedMotion: reduce, accessible: !reduce);
      await tester.pump(const Duration(seconds: 30));
      expect(pageIndex(tester), 0);
      await tester.drag(find.byType(PageView), const Offset(-600, 0));
      await tester.pumpAndSettle();
      expect(pageIndex(tester), 1);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets(
    'English journal slide and start fit a small screen with large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var starts = 0;
      await mount(
        tester,
        locale: 'en',
        reducedMotion: true,
        textScale: 1.5,
        start: () => starts++,
      );
      tester.widget<PageView>(find.byType(PageView)).controller!.jumpToPage(3);
      await tester.pumpAndSettle();
      final strings = lookupAppLocalizations(const Locale('en'));
      await tester.ensureVisible(
        find.text('« ${strings.onboardingJournalQuote} »'),
      );
      await tester.tap(find.text(strings.commencerDesMaintenant));
      await tester.pumpAndSettle();
      expect(starts, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
