import 'package:app4training/data/app_language.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app4training/data/globals.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/data/updates.dart';
import 'package:app4training/widgets/languages_table.dart';

import 'app_language_test.dart';
import 'languages_test.dart';
import 'updates_test.dart';

// To simplify testing the LanguagesTable widget in different locales
class TestLanguagesTable extends ConsumerWidget {
  const TestLanguagesTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
        locale: ref.watch(appLanguageProvider).locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: LanguagesTable()));
  }
}

void main() {
  testWidgets('Basic test with no language downloaded, English as appLanguage',
      (WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [
      appLanguageProvider.overrideWith(() => TestAppLanguage('en')),
      languageProvider
          .overrideWith(() => TestLanguageController(downloadedLanguages: [])),
      languageStatusProvider.overrideWith(() => TestLanguageStatus())
    ], child: const TestLanguagesTable()));

    expect(
        find.text('All languages ($countAvailableLanguages)'), findsOneWidget);
    expect(find.text('German (de)'), findsOneWidget);
    expect(find.text('English (en)'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);
    expect(find.byIcon(Icons.delete), findsOneWidget);
    expect(find.byIcon(Icons.download),
        findsNWidgets(countAvailableLanguages + 1));
    expect(find.byIcon(Icons.refresh), findsNothing);

    // Check correct sorting
    final germanPosition = tester.getTopLeft(find.text('German (de)'));
    final englishPosition = tester.getTopLeft(find.text('English (en)'));
    final frenchPosition = tester.getTopLeft(find.text('French (fr)'));
    expect(englishPosition.dy < germanPosition.dy, isTrue);
    expect(englishPosition.dy < frenchPosition.dy, isTrue);
    expect(frenchPosition.dy < germanPosition.dy, isTrue);
  });
  testWidgets('Basic test with only German downloaded, German as appLanguage',
      (WidgetTester tester) async {
    final ref = ProviderContainer(overrides: [
      appLanguageProvider.overrideWith(() => TestAppLanguage('de')),
      availableLanguagesProvider.overrideWithValue(['de', 'en', 'fr']),
      languageProvider.overrideWith(
          () => TestLanguageController(downloadedLanguages: ['de'])),
      languageStatusProvider
          .overrideWith(() => TestLanguageStatus(langWithUpdates: ['de']))
    ]);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: ref, child: const TestLanguagesTable()));

    expect(
        find.text('Alle Sprachen ($countAvailableLanguages)'), findsOneWidget);
    expect(find.text('Deutsch (de)'), findsOneWidget);
    expect(find.text('Englisch (en)'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNWidgets(1));

    expect(find.byIcon(Icons.delete), findsNWidgets(2));
    expect(find.byIcon(Icons.refresh), findsNWidgets(2));
    expect(find.byIcon(Icons.download), findsNWidgets(3));

    // Check correct sorting
    final germanPosition = tester.getTopLeft(find.text('Deutsch (de)'));
    final englishPosition = tester.getTopLeft(find.text('Englisch (en)'));
    final frenchPosition = tester.getTopLeft(find.text('Französisch (fr)'));
    expect(englishPosition.dy > germanPosition.dy, isTrue);
    expect(englishPosition.dy < frenchPosition.dy, isTrue);
    expect(frenchPosition.dy > germanPosition.dy, isTrue);
  });
  // TODO add more tests to check whether icons change according to user interaction
  // TODO test optional parameter highlightLang
}
