import 'dart:async';

import 'package:app4training/data/languages.dart';
import 'package:app4training/l10n/generated/app_localizations.dart';
import 'package:app4training/routes/error_page.dart';
import 'package:app4training/routes/home_page.dart';
import 'package:app4training/routes/onboarding/download_languages_page.dart';
import 'package:app4training/routes/onboarding/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app4training/data/globals.dart';
import 'package:app4training/routes/routes.dart';
import 'package:app4training/routes/settings_page.dart';
import 'package:app4training/routes/startup_page.dart';
import 'package:app4training/routes/view_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'languages_test.dart';

// For observing the routes that get pushed and replaced
class TestObserver extends NavigatorObserver {
  List<String> routes = [];
  List<String> replacedRoutes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    routes.add(route.settings.name ?? '');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    replacedRoutes.add(newRoute?.settings.name ?? '');
  }
}

class TestApp extends StatelessWidget {
  final TestObserver observer;
  const TestApp(this.observer, {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [observer],
      onGenerateRoute: (settings) => generateRoutes(settings),
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    );
  }
}

void main() {
  testWidgets('Test onboarding routes', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final TestObserver observer = TestObserver();
    await tester.pumpWidget(ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: TestApp(observer)));

    // Test that onboarding process get's started on first app usage
    expect(find.byType(TestApp), findsOneWidget);
    expect(find.byType(StartupPage), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byType(WelcomePage), findsOneWidget);

    // Test second onboarding step
    unawaited(Navigator.of(tester.element(find.byType(WelcomePage)))
        .pushReplacementNamed('/onboarding/2'));
    await tester.pumpAndSettle();
    expect(find.byType(DownloadLanguagesPage), findsOneWidget);

    // Go back again
    unawaited(Navigator.of(tester.element(find.byType(DownloadLanguagesPage)))
        .pushReplacementNamed('/onboarding/1'));
    await tester.pumpAndSettle();
    expect(find.byType(WelcomePage), findsOneWidget);

/*  TODO for version 0.9
    // Test third onboarding step
    unawaited(Navigator.of(tester.element(find.byType(WelcomePage)))
        .pushReplacementNamed('/onboarding/3'));
    await tester.pumpAndSettle();
    expect(find.byType(SetUpdatePrefsPage), findsOneWidget);
*/

    // Test that routes are handled
    expect(
        observer.replacedRoutes,
        orderedEquals([
          '/onboarding/1',
          '/onboarding/2',
          '/onboarding/1',
//          '/onboarding/3'
        ]));
  });

  testWidgets('Test normal startup', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'appLanguage': 'system'});
    final prefs = await SharedPreferences.getInstance();

    final TestObserver observer = TestObserver();
    await tester.pumpWidget(ProviderScope(overrides: [
      languageProvider
          .overrideWith(() => TestLanguageController(initReturns: true)),
      sharedPrefsProvider.overrideWithValue(prefs)
    ], child: TestApp(observer)));

    // Test initial route /
    expect(find.byType(TestApp), findsOneWidget);
    expect(find.byType(StartupPage), findsOneWidget);

    // Test home page
    unawaited(Navigator.of(tester.element(find.byType(StartupPage)))
        .pushNamed('/home'));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);

    // Test settings page
    unawaited(Navigator.of(tester.element(find.byType(HomePage)))
        .pushNamed('/settings'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);

    // Test viewing the forgiveness page in English
    const String viewRoute = '/view/Forgiving_Step_by_Step/en';
    unawaited(Navigator.of(tester.element(find.byType(SettingsPage)))
        .pushNamed(viewRoute));
    await tester.pumpAndSettle();
    expect(find.byType(ViewPage), findsOneWidget);
    ViewPage viewPage =
        find.byType(ViewPage).evaluate().single.widget as ViewPage;
    expect(viewPage.page, equals('Forgiving_Step_by_Step'));
    expect(viewPage.langCode, equals('en'));

    // Test that routes are handled
    expect(
        observer.routes, orderedEquals(['/', '/home', '/settings', viewRoute]));
  });

  testWidgets('Test some edge cases', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'appLanguage': 'system'});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: TestApp(TestObserver())));

    // All of the following errorneous routes should result in showing /home
    unawaited(Navigator.of(tester.element(find.byType(StartupPage)))
        .pushNamed('/view'));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);

    unawaited(Navigator.of(tester.element(find.byType(HomePage)))
        .pushNamed('/view//'));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);

    unawaited(Navigator.of(tester.element(find.byType(HomePage)))
        .pushNamed('/view/Forgiving_Step_by_Step/'));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('Test unknown route', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'appLanguage': 'system'});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: TestApp(TestObserver())));

    unawaited(Navigator.of(tester.element(find.byType(StartupPage)))
        .pushNamed('/unknown'));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorPage), findsOneWidget);
    expect(find.textContaining('Unknown route /unknown'), findsOneWidget);
  });
}
