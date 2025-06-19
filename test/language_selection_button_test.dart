import 'package:app4training/data/app_language.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/l10n/generated/app_localizations.dart';
import 'package:app4training/routes/view_page.dart';
import 'package:app4training/widgets/language_selection_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_language_test.dart';
import 'languages_test.dart';

// To simplify testing the LanguagesButton widget in different locales
class TestLanguagesButton extends ConsumerWidget {
  const TestLanguagesButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
        locale: ref.watch(appLanguageProvider).locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // we need ViewPage here because LanguagesButton uses
        // context.findAncestorWidgetOfExactType<ViewPage>() to get current page
        home: const ViewPage('Healing', 'de'));
  }
}

void main() {
  testWidgets('Test with only German downloaded, English as appLanguage',
      (WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [
      appLanguageProvider.overrideWith(() => TestAppLanguage('en')),
      languageProvider.overrideWith(() => TestLanguageController(
          downloadedLanguages: ['de'],
          pages: {'Healing': const Page('test', 'test', 'test', '1.0', null)}))
    ], child: const TestLanguagesButton()));

    expect(find.byIcon(Icons.translate), findsOneWidget);
    expect(find.text('German (de)'), findsNothing);

    await tester.tap(find.byType(LanguageSelectionButton));
    await tester.pump();

    expect(find.text('Show current page in:'), findsOneWidget);
    expect(find.text('German (de)'), findsOneWidget);
    expect(find.text('English (en)'), findsNothing);

    expect(find.byIcon(Icons.settings), findsOneWidget);
    expect(find.text('Manage languages'), findsOneWidget);
  });

  testWidgets('Test with 5 languages downloaded, German as appLanguage',
      (WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [
      appLanguageProvider.overrideWith(() => TestAppLanguage('de')),
      languageProvider.overrideWith(() => TestLanguageController(
          downloadedLanguages: ['de', 'en', 'fr', 'es', 'ar'],
          pages: {'Healing': const Page('test', 'test', 'test', '1.0', null)}))
    ], child: const TestLanguagesButton()));

    expect(find.byIcon(Icons.translate), findsOneWidget);
    expect(find.text('Deutsch (de)'), findsNothing);
    expect(find.text('Arabisch (ar)'), findsNothing);

    await tester.tap(find.byType(LanguageSelectionButton));
    await tester.pump();

    expect(find.text('Seite anzeigen auf:'), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
    expect(find.text('Sprachen verwalten'), findsOneWidget);

    // Check that all five languages are there and sorted correctly
    List<String> expectedOrder = [
      'Arabisch (ar)',
      'Deutsch (de)',
      'Englisch (en)',
      'Französisch (fr)',
      'Spanisch (es)'
    ];

    List<double> offsets = [];
    for (String lang in expectedOrder) {
      expect(find.text(lang), findsOneWidget);
      offsets.add(tester.getTopLeft(find.text(lang)).dy);
    }
    List<double> sortedOffsets = List.from(offsets);
    sortedOffsets.sort();
    expect(listEquals(offsets, sortedOffsets), isTrue);
  });

  // TODO add test for 2-column layout
}
