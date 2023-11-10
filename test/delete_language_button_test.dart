import 'package:app4training/data/globals.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:app4training/widgets/delete_language_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_page_test.dart';

/// Simulate that Language gets downloaded initially
/// and deleted when deleteResources() gets called
class TestLanguageController extends DummyLanguageController {
  @override
  Language build(String arg) {
    languageCode = arg;
    return Language(
        languageCode, const {}, const [], const {}, '', 0, DateTime.utc(2023));
  }

  @override
  Future<void> deleteResources() async {
    state =
        Language('', const {}, const [], const {}, '', 0, DateTime.utc(2023));
  }
}

void main() {
  testWidgets('Test DeleteLanguageButton', (WidgetTester tester) async {
    final testLanguageController = TestLanguageController();
    final testLanguageProvider =
        NotifierProvider.family<LanguageController, Language, String>(() {
      return testLanguageController;
    });

    final container = ProviderContainer(overrides: [
      languageProvider.overrideWithProvider(testLanguageProvider)
    ]);

    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            scaffoldMessengerKey: container.read(scaffoldMessengerKeyProvider),
            home: const Scaffold(body: DeleteLanguageButton('en')))));

    expect(find.byIcon(Icons.delete), findsOneWidget);
    expect(testLanguageController.state.downloaded, true);
    expect(container.read(languageProvider('en')).downloaded, true);

    await tester.tap(find.byType(DeleteLanguageButton));
    await tester.pump();
    expect(testLanguageController.state.downloaded, false);
    expect(container.read(languageProvider('en')).downloaded, false);
    // Snackbar visible?
    expect(find.text('Englisch (en) wurde gelöscht'), findsOneWidget);
  });

  testWidgets('Test DeleteAllLanguagesButton', (WidgetTester tester) async {
    final testLanguageProvider =
        NotifierProvider.family<LanguageController, Language, String>(() {
      return TestLanguageController();
    });

    SharedPreferences.setMockInitialValues({'appLanguage': 'fr'});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      languageProvider.overrideWithProvider(testLanguageProvider),
      sharedPrefsProvider.overrideWithValue(prefs)
    ]);

    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            scaffoldMessengerKey: container.read(scaffoldMessengerKeyProvider),
            home: const Scaffold(body: DeleteAllLanguagesButton()))));

    expect(find.byIcon(Icons.delete), findsOneWidget);

    await tester.tap(find.byType(DeleteAllLanguagesButton));
    await tester.pump();
    expect(container.read(languageProvider('ar')).downloaded, false);
    expect(container.read(languageProvider('en')).downloaded, true);
    // TODO: Why is appLanguageProvider returning English, not French?
    // print('appLanguage: ${container.read(appLanguageProvider).languageCode}');
    // expect(container.read(languageProvider('fr')).downloaded, true);
    expect(container.read(languageProvider('de')).downloaded, false);

    // TODO Snackbar visible?
//    expect(find.text('32 Sprachen gelöscht'), findsOneWidget);
  });
}
