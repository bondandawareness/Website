import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still/main.dart';
import 'package:still/opening.dart';

void main() {
  testWidgets('home retains spiral and settings return to the same home',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: StillHome(
            settingsLoader: () async => throw StateError('Offline test'))));
    await tester.pump();
    expect(
        find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is OpeningSpiralPainter),
        findsOneWidget);
    expect(find.text('Rhythm'), findsNothing);
    expect(find.byType(Switch), findsOneWidget);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pump();
    expect(find.text('Rhythm'), findsOneWidget);
    expect(find.text('Change instrument'), findsOneWidget);
    await tester.tap(find.byTooltip('Back to home'));
    await tester.pump();
    expect(find.text('Rhythm'), findsNothing);
    expect(find.text('STILL'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
