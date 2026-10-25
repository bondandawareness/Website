import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still/cinematic_spiral.dart';

void main() {
  double phase(WidgetTester tester) => (tester
          .widget<CustomPaint>(find.byWidgetPredicate(
              (w) => w is CustomPaint && w.painter is OpeningSpiralPainter))
          .painter as OpeningSpiralPainter)
      .phase;
  testWidgets('living spiral freezes in background and resumes in foreground',
      (tester) async {
    tester.binding
        .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester
        .pumpWidget(const MaterialApp(home: Scaffold(body: LivingSpiral())));
    await tester.pump(const Duration(seconds: 2));
    expect(phase(tester), greaterThan(0));
    tester.binding
        .handleAppLifecycleStateChanged(AppLifecycleState.paused);
    final stopped = phase(tester);
    await tester.pump(const Duration(seconds: 5));
    expect(phase(tester), stopped);
    tester.binding
        .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(phase(tester), isNot(stopped));
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('reduced motion leaves a static spiral', (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: LivingSpiral())));
    await tester.pump(const Duration(seconds: 5));
    expect(phase(tester), 0);
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(const SizedBox());
  });
}

