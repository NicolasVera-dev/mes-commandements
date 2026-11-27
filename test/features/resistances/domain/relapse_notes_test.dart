import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rituel/features/auth/domain/entities/auth_user.dart';
import 'package:rituel/features/auth/domain/repositories/auth_repository.dart';
import 'package:rituel/features/resistances/data/repositories/firestore_resistance_relapse_repository.dart';
import 'package:rituel/features/resistances/domain/usecases/save_relapse_note_usecase.dart';

class _Auth extends Fake implements AuthRepository {
  @override
  Stream<AuthUser?> authStateChanges() =>
      Stream.value(const AuthUser(uid: 'u', email: 'u@example.com'));
}

void main() {
  test('editing and clearing a relapse note preserves dates and streaks and isolates accounts', () async {
    final db = FakeFirebaseFirestore();
    final repo = FirestoreResistanceRelapseRepository(
      authRepository: _Auth(),
      firestore: db,
    );
    final path = db.doc('users/u/resistances/r/relapses/one');
    final date = DateTime.utc(2026, 11, 27).toIso8601String();
    await path.set({'relapsedAtUtc': date, 'previousStreakDays': 12});
    await db.doc('users/other/resistances/r/relapses/one').set({
      'note': 'Privé',
    });
    final useCase = SaveRelapseNoteUseCase(repo);
    await useCase.execute(
      resistanceId: 'r',
      relapseId: 'one',
      note: ' Une difficulté ',
    );
    expect((await repo.watchRelapses('r').first).single.note, 'Une difficulté');
    expect((await path.get()).data()!['previousStreakDays'], 12);
    expect((await path.get()).data()!['relapsedAtUtc'], date);
    await useCase.execute(resistanceId: 'r', relapseId: 'one', note: '   ');
    expect((await path.get()).data()!.containsKey('note'), false);
    expect(
      (await db.doc('users/other/resistances/r/relapses/one').get())
          .data()!['note'],
      'Privé',
    );
    expect(
      () =>
          useCase.execute(resistanceId: 'r', relapseId: 'one', note: 'x' * 301),
      throwsArgumentError,
    );
    await expectLater(
      useCase.execute(resistanceId: 'r', relapseId: 'missing', note: 'Note'),
      throwsA(anything),
    );
    expect(
      (await db.doc('users/u/resistances/r/relapses/missing').get()).exists,
      false,
    );
  });
}
