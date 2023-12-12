import 'package:app4training/data/globals.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:app4training/widgets/delete_language_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'languages_test.dart';

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

  // Trying to delete the currently selected app language is discouraged
  testWidgets('Test DeleteLanguageButton for app language',
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
            home: const Scaffold(body: DeleteLanguageButton('de')))));

    expect(find.byIcon(Icons.delete), findsOneWidget);
    // TODO test that the color of the icon is greyed out
    expect(container.read(languageProvider('de')).downloaded, true);

    await tester.tap(find.byType(DeleteLanguageButton));
    await tester.pump();
    // The ConfirmDeletionDialog should be visible now: we cancel
    expect(find.byType(ConfirmDeletionDialog), findsOneWidget);
    expect(find.text('Abbrechen'), findsOneWidget);
    expect(find.text('Löschen'), findsOneWidget);
    await (tester.tap(find.text('Abbrechen')));
    await tester.pump();
    expect(find.byType(ConfirmDeletionDialog), findsNothing);
    expect(container.read(languageProvider('de')).downloaded, true);

    // This time we really delete
    await tester.tap(find.byType(DeleteLanguageButton));
    await tester.pump();
    expect(find.text('Löschen'), findsOneWidget);
    await (tester.tap(find.text('Löschen')));
    await tester.pump();
    expect(find.byType(ConfirmDeletionDialog), findsNothing);
    expect(container.read(languageProvider('de')).downloaded, false);
  });

  testWidgets('Test DeleteAllLanguagesButton', (WidgetTester tester) async {
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
            home: const Scaffold(body: DeleteAllLanguagesButton()))));

    expect(container.read(languageProvider('ar')).downloaded, true);

    expect(find.byIcon(Icons.delete), findsOneWidget);
    await tester.tap(find.byType(DeleteAllLanguagesButton));
    await tester.pump();

    expect(container.read(languageProvider('ar')).downloaded, false);
    expect(container.read(languageProvider('en')).downloaded, false);
    expect(container.read(languageProvider('de')).downloaded, true);
    // Snackbar visible?
    expect(find.text('33 Sprachen gelöscht'), findsOneWidget);
  });
}
