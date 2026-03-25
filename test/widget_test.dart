import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:demo_app/features/counter/domain/entities/command.dart';
import 'package:demo_app/features/counter/presentation/state/command_provider.dart';
import 'package:demo_app/features/counter/presentation/pages/home_page.dart';

Widget _buildTestApp({List<Command>? commands}) {
  return ChangeNotifierProvider(
    create: (_) => CommandProvider(
      commands: commands ??
          [
            const Command(
              id: 'test-1',
              title: 'Commandement test',
              target: 5,
              progress: 0,
              frequency: Frequency.daily,
            ),
          ],
    ),
    child: const MaterialApp(
      home: HomePage(),
    ),
  );
}

void main() {
  testWidgets('HomePage affiche le titre de l\'application',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pump();

    expect(find.text('Mes commandements'), findsOneWidget);
  });

  testWidgets('HomePage affiche les commandements',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pump();

    expect(find.text('Commandement test'), findsOneWidget);
  });

  testWidgets('HomePage affiche le bouton "Nouveau commandement"',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pump();

    expect(find.text('Nouveau commandement'), findsOneWidget);
  });

  testWidgets('HomePage affiche un état vide quand aucun commandement',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp(commands: []));
    await tester.pump();

    expect(find.text('Aucun commandement trouvé'), findsOneWidget);
  });

  testWidgets('Taper sur une carte incrémente la progression',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pump();

    expect(find.text('0 / 5'), findsOneWidget);

    await tester.tap(find.text('Commandement test'));
    await tester.pumpAndSettle();

    expect(find.text('1 / 5'), findsOneWidget);
  });
}
