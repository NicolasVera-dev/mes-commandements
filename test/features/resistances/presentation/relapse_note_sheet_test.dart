import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rituel/app/localization/localization.dart';
import 'package:rituel/features/auth/domain/entities/auth_user.dart';
import 'package:rituel/features/auth/domain/repositories/auth_repository.dart';
import 'package:rituel/features/resistances/data/repositories/firestore_resistance_relapse_repository.dart';
import 'package:rituel/features/resistances/domain/entities/resistance_relapse.dart';
import 'package:rituel/features/resistances/domain/repositories/resistance_relapse_repository.dart';
import 'package:rituel/features/resistances/presentation/widgets/relapse_note_sheet.dart';

class _Auth extends Fake implements AuthRepository {
  @override
  Stream<AuthUser?> authStateChanges() =>
      Stream.value(const AuthUser(uid: 'u', email: 'u@example.com'));
}

void main() {
  for (final locale in ['fr', 'en']) {
    testWidgets('$locale: add, edit and remove a note on an existing relapse', (
      tester,
    ) async {
      final db = FakeFirebaseFirestore();
      final repo = FirestoreResistanceRelapseRepository(
        authRepository: _Auth(),
        firestore: db,
      );
      final doc = db.doc('users/u/resistances/r/relapses/one');
      await doc.set({
        'relapsedAtUtc': DateTime.utc(2026, 11, 27).toIso8601String(),
        'previousStreakDays': 12,
      });
      final strings = lookupAppLocalizations(Locale(locale));
      await tester.pumpWidget(
        Provider<ResistanceRelapseRepository>.value(
          value: repo,
          child: MaterialApp(
            locale: Locale(locale),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: StreamBuilder<List<ResistanceRelapse>>(
                stream: repo.watchRelapses('r'),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  return TextButton(
                    onPressed: () =>
                        showRelapseNoteSheet(context, snapshot.data!.single),
                    child: const Text('note'),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('note'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.enterText(find.byType(TextField), 'Une note après coup');
      await tester.pump();
      await tester.tap(find.text(strings.enregistrer));
      await tester.pumpAndSettle();
      expect((await doc.get()).data()!['note'], 'Une note après coup');
      await tester.tap(find.text('note'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Une note après coup',
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(
        tester.getCenter(find.text(strings.supprimer)).dy,
        tester.getCenter(find.text(strings.enregistrer)).dy,
      );
      await tester.enterText(find.byType(TextField), 'Note modifiée');
      await tester.pump();
      await tester.tap(find.text(strings.enregistrer));
      await tester.pumpAndSettle();
      await tester.tap(find.text('note'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.supprimer));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(strings.supprimer),
        ),
      );
      await tester.pumpAndSettle();
      expect((await doc.get()).data()!.containsKey('note'), false);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
      expect((await doc.get()).data()!['previousStreakDays'], 12);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
