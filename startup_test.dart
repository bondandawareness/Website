import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:still/main.dart';

void main() {
  testWidgets('settings failure releases switches and offers retry',
      (tester) async {
    tester.view.physicalSize = const Size(480, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: StillHome(
      initialSettings: true,
      settingsLoader: () async => throw StateError('Storage unavailable'),
    )));
    await tester.pump();
    expect(find.textContaining('Startup failed:'), findsOneWidget);
    expect(find.text('Retry reminders'), findsOneWidget);
    for (final tile
        in tester.widgetList<SwitchListTile>(find.byType(SwitchListTile))) {
      expect(tile.onChanged, isNotNull);
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('unresponsive settings cannot leave controls disabled forever',
      (tester) async {
    tester.view.physicalSize = const Size(480, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final pending = Completer<SharedPreferences>();
    await tester.pumpWidget(MaterialApp(
        home: StillHome(
            initialSettings: true, settingsLoader: () => pending.future)));
    expect(
        tester
            .widget<SwitchListTile>(find.byType(SwitchListTile).first)
            .onChanged,
        isNull);
    await tester.pump(const Duration(seconds: 9));
    await tester.pump();
    expect(find.textContaining('TimeoutException'), findsOneWidget);
    expect(
        tester
            .widget<SwitchListTile>(find.byType(SwitchListTile).first)
            .onChanged,
        isNotNull);
    // A late platform reply must not restart scheduling after the timeout.
    SharedPreferences.setMockInitialValues({});
    pending.complete(await SharedPreferences.getInstance());
    await tester.pump();
    expect(find.text('Updating reminders…'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
