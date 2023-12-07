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

// Simulate that the specified languages are downloaded with the one page we use
class TestLanguageController extends LanguageController {
  @override
  Language build(String arg) {
    Map<String, Page> pages = {};
    List<String> pageIndex = [];
    for (String page in [
      'Prayer',
      'Forgiving_Step_by_Step',
      'Hearing_from_God',
      'Training_Meeting_Outline',
      'Overcoming_Fear_and_Anger'
    ]) {
      pages[page] = Page(page, page.replaceAll('_', ' '), 'test', '1.0');
      pageIndex.add(page);
    }
    return Language(arg, pages, pageIndex, const {}, '', 0, DateTime.utc(2023));
  }
}

/// Build everything we need to test MainDrawer:
/// i18n to test translated menu; onGenerateRoute for opening settings
class TestApp extends ConsumerWidget {
  final String appLanguage;
  const TestApp(this.appLanguage, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
        onGenerateRoute: (settings) => generateRoutes(settings, ref),
        locale: Locale(appLanguage),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
            appBar: AppBar(title: const Text('4training')),
            drawer: const MainDrawer('Forgiving_Step_by_Step', 'en')));
  }
}

void main() {
  final testLanguageProvider =
      NotifierProvider.family<LanguageController, Language, String>(() {
    return TestLanguageController();
  });

  testWidgets('Basic drawer test: categories + their content visible?',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      languageProvider.overrideWithProvider(testLanguageProvider)
    ], child: const TestApp('en')));

    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(find.text('Inner Healing'), findsNothing);

    final ScaffoldState state = tester.firstState(find.byType(Scaffold));
    state.openDrawer();
    await tester.pumpAndSettle();

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
  });

  testWidgets('Test main navigation in German', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      languageProvider.overrideWithProvider(testLanguageProvider)
    ], child: const TestApp('de')));

    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(find.text('Innere Heilung'), findsNothing);
    expect(find.text('[en]'), findsNothing);

    final ScaffoldState state = tester.firstState(find.byType(Scaffold));
    state.openDrawer();
    await tester.pumpAndSettle();

    expect(find.text('Innere Heilung'), findsOneWidget);
    expect(find.text('Grundlagen'), findsOneWidget);

    // Headline, Settings, About visible?
    expect(find.text('Inhalt'), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
    expect(find.text('Einstellungen'), findsOneWidget);
    expect(find.text('Über...'), findsOneWidget);

    // TODO: add test for the translation links
    // For unknown reason this test fails when invoked via flutter test,
    // but it succeeds with flutter run test/main_drawer_test.dart
    // expect(find.text('[en]'), findsNWidgets(3));
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
}
