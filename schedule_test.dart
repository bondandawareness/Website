import 'package:flutter_test/flutter_test.dart';
import 'package:still/schedule.dart';

void main() {
  test('reopening does not change the daily sequence', () {
    final first = DailyRandom(DateTime(2026, 10, 20, 9), 7182);
    final reopened = DailyRandom(DateTime(2026, 10, 20, 15), 7182);
    expect(List.generate(40, (_) => first.nextInt(21)),
        List.generate(40, (_) => reopened.nextInt(21)));
  });

  test('balanced intervals stay in the 25â€“45 minute range', () {
    final random = DailyRandom(DateTime(2026, 10, 20), 7182);
    for (var i = 0; i < 1000; i++) {
      expect(25 + random.nextInt(21), inInclusiveRange(25, 45));
    }
  });

  test('all six instruments rotate without consecutive repeats', () {
    for (final days in [1, 2, 3, 4, 5]) {
      final selections = List.generate(
          60,
          (i) => soundIndexForDay(
              DateTime.utc(2026, 1, 1 + i * days), 7182, days));
      expect(selections.toSet().length, 6);
      for (var i = 1; i < selections.length; i++) {
        expect(selections[i], isNot(selections[i - 1]));
      }
    }
  });

  test('instrument stays the same throughout the local calendar day', () {
    expect(soundIndexForDay(DateTime(2026, 10, 25, 0), 7182, 3),
        soundIndexForDay(DateTime(2026, 10, 25, 23, 59), 7182, 3));
  });
}
