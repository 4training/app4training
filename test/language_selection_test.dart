import 'package:app4training/data/app_language.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:app4training/routes/view_page.dart';
import 'package:app4training/widgets/language_selection.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app4training/data/globals.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'languages_test.dart';

// Simulate that the specified languages are downloaded with the one page we use
class TestLanguageController extends DummyLanguageController {
  // ignore: avoid_public_notifier_properties
  final List<String> downloadedLanguages;
  TestLanguageController(this.downloadedLanguages);

  @override
  Language build(String arg) {
    languageCode = downloadedLanguages.contains(arg) ? arg : '';
    return Language(
        languageCode,
        const {'Healing': Page('test', 'test', 'test', '1.0')},
        const [],
        const {},
        '',
        0,
        DateTime.utc(2023));
  }
}

// To simplify testing the LanguagesButton widget in different locales
class TestLanguagesButton extends ConsumerWidget {
  const TestLanguagesButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLanguage appLanguage = ref.watch(appLanguageProvider);

    return MaterialApp(
        locale: appLanguage.locale,
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
    final testLanguageProvider =
        NotifierProvider.family<LanguageController, Language, String>(() {
      return TestLanguageController(['de']);
    });

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      languageProvider.overrideWithProvider(testLanguageProvider)
    ], child: const TestLanguagesButton()));

    expect(find.byIcon(Icons.translate), findsOneWidget);
    expect(find.text('German (de)'), findsNothing);

    await tester.tap(find.byType(LanguagesButton));
    await tester.pump();

    expect(find.text('Show current page in:'), findsOneWidget);
    expect(find.text('German (de)'), findsOneWidget);
    expect(find.text('English (en)'), findsNothing);

    expect(find.byIcon(Icons.settings), findsOneWidget);
    expect(find.text('Manage languages'), findsOneWidget);
  });

  testWidgets('Test with 5 languages downloaded, German as appLanguage',
      (WidgetTester tester) async {
    final testLanguageProvider =
        NotifierProvider.family<LanguageController, Language, String>(() {
      return TestLanguageController(['de', 'en', 'fr', 'es', 'ar']);
    });

    SharedPreferences.setMockInitialValues({'appLanguage': 'de'});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      languageProvider.overrideWithProvider(testLanguageProvider)
    ], child: const TestLanguagesButton()));

    expect(find.byIcon(Icons.translate), findsOneWidget);
    expect(find.text('Deutsch (de)'), findsNothing);
    expect(find.text('Arabisch (ar)'), findsNothing);

    await tester.tap(find.byType(LanguagesButton));
    await tester.pump();

    expect(find.text('Seite anzeigen auf:'), findsOneWidget);
    expect(find.text('Deutsch (de)'), findsOneWidget);
    expect(find.text('Arabisch (ar)'), findsOneWidget);

    expect(find.byIcon(Icons.settings), findsOneWidget);
    expect(find.text('Sprachen verwalten'), findsOneWidget);
  });

  // TODO add test for 2-column layout
}
