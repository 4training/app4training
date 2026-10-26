import 'dart:async';

import 'package:app4training/features/perf/perf_logger.dart';
import 'package:app4training/features/perf/perf_navigator_observer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'perf_logger_test.dart';

void main() {
  tearDown(PerfLogger.reset);

  final navigatorKey = GlobalKey<NavigatorState>();

  Widget app() => MaterialApp(
    navigatorKey: navigatorKey,
    navigatorObservers: [PerfNavigatorObserver()],
    initialRoute: '/home',
    onGenerateRoute:
        (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => Text(settings.name!),
        ),
  );

  Future<List<Map<String, dynamic>>> screenEvents(fileSystem) async {
    await PerfLogger.flush();
    return (await readRecords(
      fileSystem,
    )).where((r) => r['name'] == 'screen').toList();
  }

  testWidgets('opening a worksheet records the screen kind only', (
    tester,
  ) async {
    final fileSystem = startLogger();
    await tester.pumpWidget(app());

    navigatorKey.currentState!.pushNamed('/view/Healing/de');
    await tester.pumpAndSettle();

    final events = await screenEvents(fileSystem);
    // initialRoute '/home' makes the Navigator push '/' first
    expect(events.map((e) => e['screen']), ['/', 'home', 'view']);
    // No page name or language code (no PII in the perf logs)
    expect(
      events.last.keys,
      unorderedEquals(['t', 'name', 'atUs', 'screen', 'depth']),
    );
  });

  testWidgets('replacing a screen (startup -> worksheet) records it', (
    tester,
  ) async {
    final fileSystem = startLogger();
    await tester.pumpWidget(app());

    navigatorKey.currentState!.pushReplacementNamed('/view/Healing/de');
    await tester.pumpAndSettle();

    final events = await screenEvents(fileSystem);
    expect(events.last['screen'], 'view');
  });

  testWidgets('going back records the screen that is visible again', (
    tester,
  ) async {
    final fileSystem = startLogger();
    await tester.pumpWidget(app());
    navigatorKey.currentState!.pushNamed('/view/Healing/de');
    await tester.pumpAndSettle();
    navigatorKey.currentState!.pushNamed('/settings');
    await tester.pumpAndSettle();

    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();

    final events = await screenEvents(fileSystem);
    expect(events.last['screen'], 'view');
  });

  testWidgets('records how many screens are on the stack', (tester) async {
    final fileSystem = startLogger();
    await tester.pumpWidget(app()); // '/' and '/home'
    navigatorKey.currentState!.pushNamed('/view/Healing/de');
    await tester.pumpAndSettle();
    // A dialog is no screen of its own
    unawaited(
      showDialog<void>(
        context: navigatorKey.currentContext!,
        builder: (_) => const Text('dialog'),
      ),
    );
    await tester.pumpAndSettle();
    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();

    final events = await screenEvents(fileSystem);
    expect(events.map((e) => e['depth']), [1, 2, 3, 3, 2]);
  });
}
