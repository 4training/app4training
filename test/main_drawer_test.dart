import 'package:app4training/data/languages.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:app4training/routes/routes.dart';
import 'package:app4training/widgets/main_drawer.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app4training/data/globals.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'languages_test.dart';
import 'routes_test.dart';

// Simulate that five pages are downloaded in most languages.
// French only has "Prayer" available.
class TestLanguageController extends LanguageController {
  @override
  Language build(String arg) {
    Map<String, String> testPageList = {
      'Prayer': 'Gebet',
      'Forgiving_Step_by_Step': 'Schritte der Vergebung',
      'Hearing_from_God': 'Gottes Reden wahrnehmen',
      'Training_Meeting_Outline': 'Ablauf der Trainings-Treffen',
      'Overcoming_Fear_and_Anger': 'Angst und Wut überwinden'
    };
    Map<String, Page> pages = {};
    List<String> pageIndex = [];
    for (var entry in testPageList.entries) {
      String page = entry.key;
      if ((arg == 'fr') && (page != 'Prayer')) continue;
      // English or German title...
      String title = (arg == 'en') ? page.replaceAll('_', ' ') : entry.value;
      pages[page] = Page(page, title, 'test', '1.0');
      pageIndex.add(page);
    }
    return Language(arg, pages, pageIndex, const {}, '', 0, DateTime.utc(2023));
  }
}

/// Build everything we need to test MainDrawer:
/// i18n to test translated menu; onGenerateRoute for opening settings
class TestApp extends ConsumerWidget {
  final String appLanguage;
  final String pageName;
  final String pageLanguage;
  final TestObserver? _navigatorObserver;
  // for snackbar testing
  final GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey;
  const TestApp(this.appLanguage,
      {this.pageName = 'Forgiving_Step_by_Step',
      this.pageLanguage = 'en',
      TestObserver? navigatorObserver,
      this.scaffoldMessengerKey,
      super.key})
      : _navigatorObserver = navigatorObserver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
        locale: Locale(appLanguage),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        onGenerateRoute: (settings) => generateRoutes(settings, ref),
        scaffoldMessengerKey: scaffoldMessengerKey,
        navigatorObservers:
            (_navigatorObserver != null) ? [_navigatorObserver] : [],
        home: Scaffold(
            appBar: AppBar(title: const Text('4training')),
            drawer: MainDrawer(pageName, pageLanguage)));
  }
}

void main() {
  final testLanguageProvider =
      NotifierProvider.family<LanguageController, Language, String>(() {
    return TestLanguageController();
  });

  testWidgets('Basic drawer test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final testObserver = TestObserver();
    await tester.pumpWidget(ProviderScope(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      languageProvider.overrideWithProvider(testLanguageProvider)
    ], child: TestApp('en', navigatorObserver: testObserver)));

    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(find.text('Inner Healing'), findsNothing);

    final ScaffoldState state = tester.firstState(find.byType(Scaffold));
    state.openDrawer();
    await tester.pumpAndSettle();

    // Are categories + their content visible?
    expect(find.text('Inner Healing'), findsOneWidget);
    expect(find.text('Essentials'), findsOneWidget);
    // the Essentials category should be expanded
    expect(find.text('Forgiving Step by Step'), findsOneWidget);
    expect(find.text('Hearing from God'), findsOneWidget);
    // the Inner Healing category shouldn't be expanded
    expect(find.text('Overcoming Fear and Anger'), findsNothing);

    expect(find.byIcon(Icons.expand_more), findsNWidgets(4));
    await tester.tap(find.text('Inner Healing'));
    await tester.pumpAndSettle();
    expect(find.text('Overcoming Fear and Anger'), findsOneWidget);

    // Headline + Settings visible?
    expect(find.text('Content'), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Click on one page and verify it gets opened
    await tester.tap(find.text('Hearing from God'));
    await tester.pump();
    expect(testObserver.routes.last, equals('/view/Hearing_from_God/en'));
  });

  testWidgets('Test main navigation in German', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'appLanguage': 'de'}); // important!
    final prefs = await SharedPreferences.getInstance();
    final testObserver = TestObserver();
    await tester.pumpWidget(ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          languageProvider.overrideWithProvider(testLanguageProvider)
        ],
        child: TestApp('de',
            pageLanguage: 'de', navigatorObserver: testObserver)));

    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(find.text('Innere Heilung'), findsNothing);

    final ScaffoldState state = tester.firstState(find.byType(Scaffold));
    state.openDrawer();
    await tester.pumpAndSettle();

    expect(find.text('Innere Heilung'), findsOneWidget);
    expect(find.text('Grundlagen'), findsOneWidget);
    // the Essentials category should be expanded
    expect(find.text('Schritte der Vergebung'), findsOneWidget);
    expect(find.text('Gottes Reden wahrnehmen'), findsOneWidget);

    // Headline, Settings, About visible?
    expect(find.text('Inhalt'), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
    expect(find.text('Einstellungen'), findsOneWidget);
    expect(find.text('Über...'), findsOneWidget);

    // Click on one page and verify it gets opened
    await tester.tap(find.text('Gottes Reden wahrnehmen'));
    await tester.pump();
    expect(testObserver.routes.last, equals('/view/Hearing_from_God/de'));
  });

  testWidgets('Test that we continue in selected different language',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'appLanguage': 'de'}); // important!
    final prefs = await SharedPreferences.getInstance();
    final testObserver = TestObserver();
    await tester.pumpWidget(ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          languageProvider.overrideWithProvider(testLanguageProvider)
        ],
        child: TestApp('de',
            pageLanguage: 'en', navigatorObserver: testObserver)));

    final ScaffoldState state = tester.firstState(find.byType(Scaffold));
    state.openDrawer();
    await tester.pumpAndSettle();

    // Currently we have Forgiving_Step_by_Step/en open. When clicking
    // on a link the next worksheet should get loaded in English as well
    await tester.tap(find.text('Gottes Reden wahrnehmen'));
    await tester.pump();
    expect(testObserver.routes.last, equals('/view/Hearing_from_God/en'));
  });

  testWidgets('Test fallback when worksheet is not available in other language',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'appLanguage': 'de'}); // important!
    final prefs = await SharedPreferences.getInstance();
    final testObserver = TestObserver();
    final container = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      languageProvider.overrideWithProvider(testLanguageProvider)
    ]);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: TestApp('de',
            pageName: 'Prayer',
            pageLanguage: 'fr',
            scaffoldMessengerKey: container.read(scaffoldMessengerKeyProvider),
            navigatorObserver: testObserver)));

    final ScaffoldState state = tester.firstState(find.byType(Scaffold));
    state.openDrawer();
    await tester.pumpAndSettle();

    // Currently we have Prayer/fr open. Hearing from God is missing in French,
    // so when clicking on it we should get redirected to its German version
    await tester.tap(find.text('Gottes Reden wahrnehmen'));
    await tester.pump();
    expect(testObserver.routes.last, equals('/view/Hearing_from_God/de'));
    // Snackbar visible?
    expect(find.textContaining('Sprache zurückgesetzt auf Deutsch'),
        findsOneWidget);
  });

  testWidgets('Make sure drawer is closed after returning from settings',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      languageProvider.overrideWithProvider(testLanguageProvider)
    ], child: const TestApp('en')));

    expect(find.byIcon(Icons.menu), findsOneWidget);

    final ScaffoldState state = tester.firstState(find.byType(Scaffold));
    state.openDrawer();
    await tester.pumpAndSettle();
    expect(find.text('Essentials'), findsOneWidget);

    // Opening settings and closing them again
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(Scaffold))).pop();
    await tester.pumpAndSettle();

    expect(state.isDrawerOpen, false);
    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(find.text('Essentials'), findsNothing);
  });

  testWidgets('Test error message when appLanguage is not downloaded',
      (WidgetTester tester) async {
    final dummyLanguageProvider =
        NotifierProvider.family<LanguageController, Language, String>(() {
      return DummyLanguageController();
    });
    SharedPreferences.setMockInitialValues({'appLanguage': 'de'});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      languageProvider.overrideWithProvider(dummyLanguageProvider)
    ], child: const TestApp('de')));

    expect(find.text('Einstellungen'), findsNothing);
    final ScaffoldState state = tester.firstState(find.byType(Scaffold));
    state.openDrawer();
    await tester.pumpAndSettle();
    expect(find.text('Einstellungen'), findsOneWidget);

    // Error message visible?
    expect(find.textContaining('Sprache ist nicht verfügbar'), findsOneWidget);
    expect(find.textContaining('lade Deutsch (de) herunter'), findsOneWidget);
  });

  // TODO: test that currently opened page is highlighted in menu
  // TODO: test the two dialogs when clicking on an icon / greyed-out icon
}
