import 'package:app4training/data/languages.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:app4training/widgets/main_drawer.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app4training/data/globals.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

void main() {
  testWidgets('Basic drawer test: categories + their content visible?',
      (WidgetTester tester) async {
    final testLanguageProvider =
        NotifierProvider.family<LanguageController, Language, String>(() {
      return TestLanguageController();
    });

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          languageProvider.overrideWithProvider(testLanguageProvider)
        ],
        child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
                appBar: AppBar(title: const Text('4training')),
                drawer: const MainDrawer('Forgiving_Step_by_Step', 'en')))));

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

    // Settings visible?
    expect(find.byIcon(Icons.settings), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Headline visible?
    expect(find.text('Content'), findsOneWidget);
  });

  testWidgets('Test main navigation in German', (WidgetTester tester) async {
    final testLanguageProvider =
        NotifierProvider.family<LanguageController, Language, String>(() {
      return TestLanguageController();
    });

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          languageProvider.overrideWithProvider(testLanguageProvider)
        ],
        child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
                appBar: AppBar(title: const Text('4training')),
                drawer: const MainDrawer('Forgiving_Step_by_Step', 'en')))));

    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(find.text('Innere Heilung'), findsNothing);
    expect(find.text('[en]'), findsNothing);

    final ScaffoldState state = tester.firstState(find.byType(Scaffold));
    state.openDrawer();
    await tester.pumpAndSettle();

    expect(find.text('Innere Heilung'), findsOneWidget);
    expect(find.text('Grundlagen'), findsOneWidget);

    // Headline visible?
    expect(find.text('Inhalt'), findsOneWidget);

    // TODO: add test for the translation links
    // For unknown reason this test fails when invoked via flutter test,
    // but it succeeds with flutter run test/main_drawer_test.dart
    // expect(find.text('[en]'), findsNWidgets(3));
  });

  // TODO: test that currently opened page is highlighted in menu
}
