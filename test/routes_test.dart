import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app4training/data/globals.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:app4training/routes/routes.dart';
import 'package:app4training/routes/settings_page.dart';
import 'package:app4training/routes/startup_page.dart';
import 'package:app4training/routes/view_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

// For observing the routes that get pushed
class TestObserver extends NavigatorObserver {
  List<String> routes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    routes.add(route.settings.name ?? '');
  }
}

// Put this in a class so that we easily have the WidgetRef for generateRoutes()
class TestApp extends ConsumerWidget {
  final TestObserver observer;
  const TestApp(this.observer, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      navigatorObservers: [observer],
      onGenerateRoute: (settings) => generateRoutes(settings, ref),
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    );
  }
}

void main() {
  testWidgets('Test default behavior', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final TestObserver observer = TestObserver();
    await tester.pumpWidget(ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: TestApp(observer)));

    // Test initial route /
    expect(find.byType(TestApp), findsOneWidget);
    expect(find.byType(StartupPage), findsOneWidget);
    StartupPage startupPage =
        find.byType(StartupPage).evaluate().single.widget as StartupPage;
    expect(startupPage.navigateTo, equals('/view'));

    expect(prefs.getString('recentPage'), null);
    expect(prefs.getString('recentLang'), null);

    // Test default view page
    Navigator.of(tester.element(find.byType(StartupPage))).pushNamed('/view');
    await tester.pumpAndSettle();
    expect(find.byType(ViewPage), findsOneWidget);
    ViewPage viewPage =
        find.byType(ViewPage).evaluate().single.widget as ViewPage;
    expect(viewPage.page, equals(Globals.defaultPage));
    expect(viewPage.langCode, equals('en'));

    // Test that recentPage and recentLang are now set in SharedPreferences
    expect(prefs.getString('recentPage'), equals(Globals.defaultPage));
    expect(prefs.getString('recentLang'), equals('en'));

    // Test settings page
    Navigator.of(tester.element(find.byType(ViewPage))).pushNamed('/settings');
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);

    // Test that routes are handled
    expect(observer.routes, orderedEquals(['/', '/view', '/settings']));
  });

  testWidgets('Test initial route with loading data from SharedPreferences',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(
        {'recentPage': 'Healing', 'recentLang': 'de'});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: TestApp(TestObserver())));

    StartupPage startupPage =
        find.byType(StartupPage).evaluate().single.widget as StartupPage;
    expect(startupPage.navigateTo, equals('/view/Healing/de'));
  });

  testWidgets('Test unknown route', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: TestApp(TestObserver())));

    Navigator.of(tester.element(find.byType(StartupPage)))
        .pushNamed('/unknown');
    await tester.pumpAndSettle();
    expect(find.byType(ErrorPage), findsOneWidget);
    expect(find.text('Warning: unknown route /unknown'), findsOneWidget);
  });
}
