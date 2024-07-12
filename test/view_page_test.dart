import 'package:app4training/data/app_language.dart';
import 'package:app4training/data/exceptions.dart';
import 'package:app4training/data/globals.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:app4training/routes/view_page.dart';
import 'package:app4training/widgets/language_selection_button.dart';
import 'package:app4training/widgets/share_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_language_test.dart';

/// Simplify testing of the ViewPage widget
class TestViewPage extends ConsumerWidget {
  static const languageCode = 'de';

  const TestViewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
        locale: ref.read(appLanguageProvider).locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ViewPage('Healing', 'de'));
  }
}

void main() {
  testWidgets('Test normal behaviour', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(overrides: [
      appLanguageProvider.overrideWith(() => TestAppLanguage('de')),
      pageContentProvider.overrideWith((ref, page) async => 'TestContent'),
      sharedPrefsProvider.overrideWith((ref) => prefs)
    ], child: const TestViewPage()));

    expect(prefs.getString('recentPage'), isNull);
    expect(prefs.getString('recentLang'), isNull);
    // First there should be the loading animation
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading content...'), findsOneWidget);
    await tester.pump();

    // Now our content should be shown
    expect(find.textContaining('TestContent'), findsOneWidget);
    // recentPage and recentLang should be set in SharedPreferences
    expect(prefs.getString('recentPage'), 'Healing');
    expect(prefs.getString('recentLang'), 'de');

    // Our two action buttons should be visible
    expect(find.byType(LanguageSelectionButton), findsOneWidget);
    expect(find.byType(ShareButton), findsOneWidget);
  });

  testWidgets('Test LanguageNotDownloadedException handling',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(overrides: [
      appLanguageProvider.overrideWith(() => TestAppLanguage('de')),
      pageContentProvider.overrideWith(
          (ref, arg) async => throw LanguageNotDownloadedException('de')),
      sharedPrefsProvider.overrideWith((ref) => prefs)
    ], child: const TestViewPage()));
    await tester.pump();

    // Now we should see a warning (in German)
    expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    expect(find.text('Warnung'), findsOneWidget);
    expect(
        find.textContaining(
            'Kann Seite "Healing" nicht auf Deutsch (de) anzeigen'),
        findsOneWidget);
    expect(find.textContaining('Sprache ist nicht verfügbar'), findsOneWidget);
  });

  testWidgets('Test PageNotFoundException handling',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(overrides: [
      appLanguageProvider.overrideWith(() => TestAppLanguage('de')),
      pageContentProvider.overrideWith(
          (ref, page) async => throw PageNotFoundException('Healing', 'de')),
      sharedPrefsProvider.overrideWith((ref) => prefs)
    ], child: const TestViewPage()));
    await tester.pump();

    // Now we should see a warning (in German)
    expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    expect(find.text('Warnung'), findsOneWidget);
    expect(
        find.textContaining(
            'Kann Seite "Healing" nicht auf Deutsch (de) anzeigen'),
        findsOneWidget);
    expect(find.textContaining('Seite Healing/de konnte nicht gefunden werden'),
        findsOneWidget);
  });

  testWidgets('Test LanguageCorruptedException handling',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(overrides: [
      appLanguageProvider.overrideWith(() => TestAppLanguage('en')),
      pageContentProvider.overrideWith((ref, page) async =>
          throw LanguageCorruptedException('de', 'BadLuck')),
      sharedPrefsProvider.overrideWith((ref) => prefs)
    ], child: const TestViewPage()));
    await tester.pump();

    // Now we should see an error message in German
    expect(find.byIcon(Icons.error), findsOneWidget);
    expect(find.text('Error'), findsOneWidget);
    expect(
        find.textContaining(
            "Language data for 'German (de)' seems to be corrupted"),
        findsOneWidget);
  });

  testWidgets('Test unexpected exception handling',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(overrides: [
      appLanguageProvider.overrideWith(() => TestAppLanguage('de')),
      pageContentProvider.overrideWith((ref, arg) async => throw TestFailure),
      sharedPrefsProvider.overrideWith((ref) => prefs)
    ], child: const TestViewPage()));
    await tester.pump();

    // Now we should see an error (internalError in German)
    expect(find.byIcon(Icons.error), findsOneWidget);
    expect(find.text('Fehler'), findsOneWidget);
    expect(find.textContaining('Ups, das tut uns leid.'), findsOneWidget);
    expect(find.textContaining('TestFailure'), findsOneWidget);
  });
}
