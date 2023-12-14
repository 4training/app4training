import 'package:app4training/data/globals.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:app4training/widgets/download_language_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'languages_test.dart';

/// Simulate that Language is not downloaded initially
/// and gets downloaded when download() is called
class TestLanguageController extends DummyLanguageController {
  @override
  Language build(String arg) {
    languageCode = arg;
    return Language(
        '', const {}, const [], const {}, '', 0, DateTime.utc(2023));
  }

  @override
  Future<bool> download({bool force = false}) async {
    state = Language(
        languageCode, const {}, const [], const {}, '', 0, DateTime.utc(2023));
    return true;
  }
}

void main() {
  testWidgets('Test DownloadLanguageButton', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'appLanguage': 'de'});
    final testLanguageController = TestLanguageController();
    final testLanguageProvider =
        NotifierProvider.family<LanguageController, Language, String>(() {
      return testLanguageController;
    });

    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      languageProvider.overrideWithProvider(testLanguageProvider),
      sharedPrefsProvider.overrideWithValue(prefs),
    ]);

    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            scaffoldMessengerKey: container.read(scaffoldMessengerKeyProvider),
            home: const Scaffold(body: DownloadLanguageButton('en')))));

    expect(find.byIcon(Icons.download), findsOneWidget);
    expect(find.byType(Container), findsNothing); // should not be highlighted
    expect(testLanguageController.state.downloaded, false);
    expect(container.read(languageProvider('en')).downloaded, false);

    await tester.tap(find.byType(DownloadLanguageButton));
    await tester.pump();
    expect(testLanguageController.state.downloaded, true);
    expect(container.read(languageProvider('en')).downloaded, true);
    // Snackbar visible?
    expect(find.text('Englisch (en) ist nun verfügbar'), findsOneWidget);
  });

  testWidgets('Test DownloadAllLanguagesButton', (WidgetTester tester) async {
    final testLanguageProvider =
        NotifierProvider.family<LanguageController, Language, String>(() {
      return TestLanguageController();
    });

    SharedPreferences.setMockInitialValues({'appLanguage': 'de'});
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
            home: const Scaffold(body: DownloadAllLanguagesButton()))));

    expect(container.read(languageProvider('ar')).downloaded, false);

    expect(find.byIcon(Icons.download), findsOneWidget);
    await tester.tap(find.byType(DownloadAllLanguagesButton));
    await tester.pump();

    expect(container.read(languageProvider('ar')).downloaded, true);
    expect(container.read(languageProvider('en')).downloaded, true);
    expect(container.read(languageProvider('de')).downloaded, true);
    // Snackbar visible?
    expect(find.text('34 Sprachen heruntergeladen'), findsOneWidget);
  });

  testWidgets('Test highlighted DownloadLanguageButton',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'appLanguage': 'de'});
    final testLanguageController = TestLanguageController();
    final testLanguageProvider =
        NotifierProvider.family<LanguageController, Language, String>(() {
      return testLanguageController;
    });

    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      languageProvider.overrideWithProvider(testLanguageProvider),
      sharedPrefsProvider.overrideWithValue(prefs),
    ]);

    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            scaffoldMessengerKey: container.read(scaffoldMessengerKeyProvider),
            home: const Scaffold(
                body: DownloadLanguageButton('en', highlight: true)))));

    expect(find.byIcon(Icons.download), findsOneWidget);
    // Test the highlighting
    expect(find.byType(Container), findsOneWidget);

    // The rest should still function as normal
    await tester.tap(find.byType(DownloadLanguageButton));
    await tester.pump();
    expect(container.read(languageProvider('en')).downloaded, true);
    // Snackbar visible?
    expect(find.text('Englisch (en) ist nun verfügbar'), findsOneWidget);
  });

  // TODO: more snackbar tests (download failed; visibility duration)
  // TODO: Test that there is a progress indicator while downloading
}
