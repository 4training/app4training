import 'dart:async';

import 'package:app4training/features/perf/perf_logger.dart';
import 'package:app4training/routes/route_stack_limiter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'perf_logger_test.dart';

void main() {
  late GlobalKey<NavigatorState> navigatorKey;

  setUp(() => navigatorKey = GlobalKey<NavigatorState>());
  tearDown(PerfLogger.reset);

  Widget app() => MaterialApp(
    navigatorKey: navigatorKey,
    navigatorObservers: [RouteStackLimiter(maxDepth: 5)],
    onGenerateRoute:
        (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => Text('screen ${settings.name}'),
        ),
  );

  Future<void> open(WidgetTester tester, String route) async {
    navigatorKey.currentState!.pushNamed(route);
    await tester.pumpAndSettle();
  }

  Future<void> back(WidgetTester tester) async {
    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
  }

  testWidgets('keeps only the newest screens once the stack is too deep', (
    tester,
  ) async {
    await tester.pumpWidget(app()); // route '/'
    for (int i = 1; i <= 6; i++) {
      await open(tester, '/view/page$i/en');
    }
    expect(find.text('screen /view/page6/en'), findsOneWidget);

    // Back walks through the four screens below, then the stack ends
    for (int i = 5; i >= 2; i--) {
      await back(tester);
      expect(find.text('screen /view/page$i/en'), findsOneWidget);
    }
    expect(navigatorKey.currentState!.canPop(), false);
  });

  testWidgets('dialogs do not push screens out of the stack', (tester) async {
    await tester.pumpWidget(app()); // route '/'
    for (int i = 1; i <= 4; i++) {
      await open(tester, '/view/page$i/en');
    }
    unawaited(
      showDialog<void>(
        context: navigatorKey.currentContext!,
        builder: (_) => const Text('dialog'),
      ),
    );
    await tester.pumpAndSettle();
    await back(tester); // closes the dialog

    for (int i = 3; i >= 1; i--) {
      await back(tester);
      expect(find.text('screen /view/page$i/en'), findsOneWidget);
    }
    await back(tester);
    expect(find.text('screen /'), findsOneWidget);
  });

  testWidgets('counts a replaced screen once (startup -> first worksheet)', (
    tester,
  ) async {
    await tester.pumpWidget(app()); // route '/'
    navigatorKey.currentState!.pushReplacementNamed('/view/page0/en');
    await tester.pumpAndSettle();
    for (int i = 1; i <= 5; i++) {
      await open(tester, '/view/page$i/en');
    }

    for (int i = 4; i >= 1; i--) {
      await back(tester);
      expect(find.text('screen /view/page$i/en'), findsOneWidget);
    }
    expect(navigatorKey.currentState!.canPop(), false);
  });

  testWidgets('dropping a screen is recorded for the perf logs', (
    tester,
  ) async {
    final fileSystem = startLogger();
    await tester.pumpWidget(app()); // route '/'
    for (int i = 1; i <= 6; i++) {
      await open(tester, '/view/page$i/en');
    }
    await PerfLogger.flush();

    final trims = (await readRecords(
      fileSystem,
    )).where((r) => r['name'] == 'stack.trimmed');
    // '/' and page1 were dropped, one at a time
    expect(trims, hasLength(2));
  });
}
