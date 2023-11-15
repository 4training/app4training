import 'package:app4training/data/app_language.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app4training/data/globals.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/data/updates.dart';
import 'package:app4training/widgets/languages_table.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_page_test.dart';

// Simulate that German is downloaded
class TestLanguageController extends DummyLanguageController {
  @override
  Language build(String arg) {
    languageCode = (arg == 'de') ? 'de' : '';
    // For 'de', Language.downloaded will be true, for the rest it will be false
    return Language(
        languageCode, const {}, const [], const {}, '', 0, DateTime.utc(2023));
  }
}

// Simulate that German has updates available
class TestLanguageStatusNotifier extends LanguageStatusNotifier {
  @override
  LanguageStatus build(String arg) {
    return LanguageStatus(arg == 'de', DateTime.utc(2023), DateTime.utc(2023));
  }
}

// To simplify testing the LanguagesTable widget in different locales
class TestLanguagesTable extends ConsumerWidget {
  const TestLanguagesTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLanguage appLanguage = ref.watch(appLanguageProvider);

    return MaterialApp(
        locale: appLanguage.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: LanguagesTable()));
  }
}

void main() {
  testWidgets('Basic test with no language downloaded, English as appLanguage',
      (WidgetTester tester) async {
    final testLanguageProvider =
        NotifierProvider.family<LanguageController, Language, String>(() {
      return DummyLanguageController();
    });

    SharedPreferences.setMockInitialValues(
        {'download_de': false, 'download_en': false});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      languageProvider.overrideWithProvider(testLanguageProvider)
    ], child: const TestLanguagesTable()));

    expect(find.text('German (de)'), findsOneWidget);
    expect(find.text('English (en)'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);
    expect(find.byIcon(Icons.delete), findsOneWidget);
    expect(find.byIcon(Icons.download),
        findsNWidgets(countAvailableLanguages + 1));
    expect(find.byIcon(Icons.refresh), findsNothing);
  });
  testWidgets('Basic test with only German downloaded, German as appLanguage',
      (WidgetTester tester) async {
    final testLanguageProvider =
        NotifierProvider.family<LanguageController, Language, String>(() {
      return TestLanguageController();
    });
    final testLanguageStatusProvider =
        NotifierProvider.family<LanguageStatusNotifier, LanguageStatus, String>(
            () {
      return TestLanguageStatusNotifier();
    });

    SharedPreferences.setMockInitialValues(
        {'download_de': true, 'download_en': false});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      languageProvider.overrideWithProvider(testLanguageProvider),
      languageStatusProvider.overrideWithProvider(testLanguageStatusProvider),
      availableLanguagesProvider.overrideWithValue(['de', 'en', 'fr'])
    ]);
    container.read(appLanguageProvider.notifier).setLocale('de');
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const TestLanguagesTable()));

    expect(find.text('Deutsch (de)'), findsOneWidget);
    expect(find.text('Englisch (en)'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNWidgets(1));

    expect(find.byIcon(Icons.delete), findsNWidgets(2));
    expect(find.byIcon(Icons.refresh), findsOneWidget);
    expect(find.byIcon(Icons.download), findsNWidgets(3));
  });
  // TODO add more tests to check whether icons change according to user interaction
}
