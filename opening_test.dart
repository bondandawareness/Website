import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still/opening.dart';

Widget app({bool reduced = false}) => MaterialApp(
        home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: StillOpening(
          homeBuilder: (_) => const Scaffold(body: Text('Home ready'))),
    ));
void main() {
  testWidgets('opening finishes and releases animation', (tester) async {
    await tester.pumpWidget(app());
    expect(find.text('Skip intro'), findsOneWidget);
    expect(find.text('Home ready'), findsNothing);
    await tester.pump(const Duration(seconds: 11));
    await tester.pump();
    expect(find.text('Home ready'), findsOneWidget);
    expect(
        find.byWidgetPredicate((widget) =>
            widget is CustomPaint && widget.painter is OpeningSpiralPainter),
        findsNothing);
  });
  testWidgets('skip opens home immediately', (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text('Skip intro'));
    await tester.pump();
    expect(find.text('Home ready'), findsOneWidget);
    await tester.pump(const Duration(seconds: 8));
    expect(tester.takeException(), isNull);
  });
  testWidgets('reduced motion bypasses intro', (tester) async {
    await tester.pumpWidget(app(reduced: true));
    expect(find.text('Home ready'), findsOneWidget);
    expect(find.text('Skip intro'), findsNothing);
  });
}
