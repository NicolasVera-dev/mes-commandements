import 'package:flutter_test/flutter_test.dart';
import 'package:rituel/app/localization/localization.dart';

void main() {
  test('completed task labels show actual counts for zero, one and many', () {
    final fr = lookupAppLocalizations(const Locale('fr'));
    expect(fr.journalCompletedCount(0, 3), '0 tâche accomplie sur 3');
    expect(fr.journalCompletedCount(1, 3), '1 tâche accomplie sur 3');
    expect(fr.journalCompletedCount(2, 3), '2 tâches accomplies sur 3');
    final en = lookupAppLocalizations(const Locale('en'));
    expect(en.journalCompletedCount(0, 3), '0 tasks completed out of 3');
    expect(en.journalCompletedCount(1, 3), '1 task completed out of 3');
    expect(en.journalCompletedCount(2, 3), '2 tasks completed out of 3');
  });
}
