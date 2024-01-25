import 'dart:async';

import 'package:app4training/data/globals.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app4training/routes/startup_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'languages_test.dart';

void main() {
  // Mocking the globalInit() function:
  // We want to be able to test all the different outcomes of the future
  Completer<String> completer = Completer<String>();
  Future<String> mockInitFunction() {
    return completer.future;
  }

  // For tracking route changes
  String? route; // make sure to reset the variable before the next test
  Route<Object?> generateRoutes(RouteSettings settings) {
    route = settings.name;
    return MaterialPageRoute<void>(builder: (_) => const Text('Mock'));
  }

  testWidgets('Test normal behaviour', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(
        {'appLanguage': 'de', 'checkFrequency': 'weekly'});
    final prefs = await SharedPreferences.getInstance();
    expect(route, isNull);
    await tester.pumpWidget(ProviderScope(
        overrides: [
          languageProvider
              .overrideWith(() => TestLanguageController(initReturns: true)),
          sharedPrefsProvider.overrideWith((ref) => prefs)
        ],
        child: MaterialApp(
            home: const StartupPage(), onGenerateRoute: generateRoutes)));
    // First there should be the loading animation
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading'), findsOneWidget);
    await tester.pump();
    expect(route, equals('/home')); // Now we went on to this route
  });

  testWidgets('Test different routing when no languages are downloaded',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'appLanguage': 'de'});
    final prefs = await SharedPreferences.getInstance();
    route = null;
    await tester.pumpWidget(ProviderScope(
        overrides: [
          languageProvider.overrideWith(
              () => TestLanguageController(downloadedLanguages: [])),
          sharedPrefsProvider.overrideWith((ref) => prefs)
        ],
        child: MaterialApp(
            home: const StartupPage(), onGenerateRoute: generateRoutes)));
    expect(route, equals('/onboarding/2'));
  });

  testWidgets('Test continuing to third onboarding step',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'appLanguage': 'de'});
    final prefs = await SharedPreferences.getInstance();
    route = null;
    await tester.pumpWidget(ProviderScope(
        overrides: [
          languageProvider
              .overrideWith(() => TestLanguageController(initReturns: true)),
          sharedPrefsProvider.overrideWith((ref) => prefs)
        ],
        child: MaterialApp(
            home: const StartupPage(), onGenerateRoute: generateRoutes)));
    await tester.pump();
    expect(route, equals('/onboarding/3'));
  });

  testWidgets('Test failing initFunction', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'appLanguage': 'de'});
    final prefs = await SharedPreferences.getInstance();
    completer = Completer();
    route = null;
    await tester.pumpWidget(ProviderScope(
        overrides: [sharedPrefsProvider.overrideWith((ref) => prefs)],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: StartupPage(initFunction: mockInitFunction),
          onGenerateRoute: generateRoutes,
        )));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading'), findsOneWidget);
    completer.completeError("Failed");
    await tester.pump();
    expect(find.text('Loading'), findsNothing);
    expect(find.textContaining('Failed'), findsOneWidget);
    expect(route, isNull);
  });

  testWidgets('Test loading recent page from SharedPreferences',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'appLanguage': 'en',
      'checkFrequency': 'weekly',
      'recentPage': 'Healing',
      'recentLang': 'de'
    });
    final prefs = await SharedPreferences.getInstance();
    route = null;
    await tester.pumpWidget(ProviderScope(
        overrides: [
          languageProvider
              .overrideWith(() => TestLanguageController(initReturns: true)),
          sharedPrefsProvider.overrideWithValue(prefs)
        ],
        child: MaterialApp(
            home: const StartupPage(), onGenerateRoute: generateRoutes)));

    await tester.pump();
    expect(route, equals('/view/Healing/de'));

    // This time German isn't loaded so recent page should get ignored
    route = null;
    final ref = ProviderContainer(overrides: [
      languageProvider.overrideWith(() => TestLanguageController(
          downloadedLanguages: ['en'], initReturns: true)),
      sharedPrefsProvider.overrideWithValue(prefs)
    ]);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: ref,
        child: MaterialApp(
            home: const StartupPage(), onGenerateRoute: generateRoutes)));

    await tester.pump();
    expect(route, equals('/home'));
  });
}
