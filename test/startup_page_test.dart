import 'dart:async';

import 'package:app4training/data/languages.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app4training/routes/startup_page.dart';

import 'languages_test.dart';

/// Simulate that no language is available
class TestLanguageController extends DummyLanguageController {
  @override
  Future<bool> init() async {
    return false;
  }
}

void main() {
  // Mocking the globalInit() function:
  // We want to be able to test all the different outcomes of the future
  Completer completer = Completer();
  Future mockInitFunction() {
    return completer.future;
  }

  // For tracking route changes
  String? route; // make sure to reset the variable before the next test
  Route<Object?> generateRoutes(RouteSettings settings) {
    route = settings.name;
    return MaterialPageRoute<void>(builder: (_) => const Text('Mock'));
  }

  testWidgets('Test normal behaviour', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: StartupPage(navigateTo: '/test', initFunction: mockInitFunction),
      onGenerateRoute: generateRoutes,
    ));
    // First there should be the loading animation
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading'), findsOneWidget);
    expect(route, isNull);
    completer.complete();

    // not sure why runAsync(), idle() and pump() are necessary, but they are...
    await tester.runAsync(() async {
      await tester.idle();
      await tester.pump();
      expect(route, equals('/test')); // Now we went on to this route
    });
  });

  testWidgets('Test different routing when no languages are downloaded',
      (WidgetTester tester) async {
    final testLanguageProvider =
        NotifierProvider.family<LanguageController, Language, String>(() {
      return TestLanguageController();
    });

    final startupPage = StartupPage(navigateTo: '/test');
    await tester.pumpWidget(ProviderScope(overrides: [
      languageProvider.overrideWithProvider(testLanguageProvider)
    ], child: MaterialApp(home: startupPage)));
    expect(startupPage.navigateTo, equals('/downloadlanguages'));
  });

  testWidgets('Test failing initFunction', (WidgetTester tester) async {
    completer = Completer();
    route = null;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: StartupPage(navigateTo: '/test', initFunction: mockInitFunction),
      onGenerateRoute: generateRoutes,
    ));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading'), findsOneWidget);
    completer.completeError("Failed");
    await tester.pump();
    expect(find.text('Loading'), findsNothing);
    expect(find.textContaining('Failed'), findsOneWidget);
    expect(route, isNull);
  });
}
