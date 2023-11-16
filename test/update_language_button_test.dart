import 'package:app4training/data/globals.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/data/updates.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:app4training/widgets/update_language_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_page_test.dart';

/// Simulate that Language gets downloaded initially
/// and that it has a newer timestamp when it gets downloaded again
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

  @override
  Future<bool> download({bool force = false}) async {
    if (force == true) deleteResources();
    state = Language(languageCode, const {}, const [], const {}, '', 0,
        DateTime.utc(2023, 10, 1));
    return true;
  }
}

/// For testing: Simulates that updates are available when checking for updates
class TestLanguageStatusNotifier extends LanguageStatusNotifier {
  @override
  Future<int> check() async {
    state = LanguageStatus(true, state.downloadTimestamp, DateTime(2023, 11));
    return 1;
  }
}

void main() {
  testWidgets('Test UpdateLanguageButton', (WidgetTester tester) async {
    final container = ProviderContainer(overrides: [
      languageProvider.overrideWith(() => TestLanguageController()),
      languageStatusProvider.overrideWith(() => TestLanguageStatusNotifier())
    ]);

    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            scaffoldMessengerKey: container.read(scaffoldMessengerKeyProvider),
            home: const Scaffold(body: UpdateLanguageButton('en')))));

    expect(find.byIcon(Icons.refresh), findsOneWidget);
    expect(container.read(languageProvider('en')).downloaded, true);
    expect(container.read(languageProvider('en')).downloadTimestamp,
        equals(DateTime.utc(2023, 1, 1)));
    expect(
        container.read(languageStatusProvider('en')).updatesAvailable, false);

    await container.read(languageStatusProvider('en').notifier).check();
    expect(container.read(languageStatusProvider('en')).updatesAvailable, true);

    await tester.tap(find.byType(UpdateLanguageButton));
    await tester.pump();
    expect(container.read(languageProvider('en')).downloadTimestamp,
        equals(DateTime.utc(2023, 10, 1)));
    expect(
        container.read(languageStatusProvider('en')).updatesAvailable, false);
    // Snackbar visible?
    expect(find.text('Englisch (en) ist nun auf dem aktuellsten Stand'),
        findsOneWidget);
  });

  testWidgets('Test UpdateAllLanguagesButton: Updating 3 languages',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'appLanguage': 'de'});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      languageProvider.overrideWith(() => TestLanguageController()),
      languageStatusProvider.overrideWith(() => TestLanguageStatusNotifier()),
      sharedPrefsProvider.overrideWithValue(prefs)
    ]);

    // Simulate that there are updates for these three languages available
    for (String languageCode in ['de', 'en', 'fr']) {
      await container
          .read(languageStatusProvider(languageCode).notifier)
          .check();
    }
    expect(container.read(updatesAvailableProvider), true);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            scaffoldMessengerKey: container.read(scaffoldMessengerKeyProvider),
            home: const Scaffold(body: UpdateAllLanguagesButton()))));

    expect(find.byIcon(Icons.refresh), findsOneWidget);
    await tester.tap(find.byType(UpdateAllLanguagesButton));
    await tester.pump();

    expect(container.read(updatesAvailableProvider), false);
    expect(find.byIcon(Icons.refresh), findsNothing);
    expect(container.read(languageProvider('ar')).downloadTimestamp,
        equals(DateTime.utc(2023, 1, 1)));
    expect(container.read(languageProvider('de')).downloadTimestamp,
        equals(DateTime.utc(2023, 10, 1)));
    expect(
        container.read(languageStatusProvider('fr')).updatesAvailable, false);

    // Snackbar visible?
    expect(find.text('3 Sprachen aktualisiert'), findsOneWidget);
  });

  testWidgets('Test UpdateAllLanguagesButton: Updating one language',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'appLanguage': 'de'});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      languageProvider.overrideWith(() => TestLanguageController()),
      languageStatusProvider.overrideWith(() => TestLanguageStatusNotifier()),
      sharedPrefsProvider.overrideWithValue(prefs)
    ]);
    await container.read(languageStatusProvider('de').notifier).check();

    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            scaffoldMessengerKey: container.read(scaffoldMessengerKeyProvider),
            home: const Scaffold(body: UpdateAllLanguagesButton()))));

    expect(find.byIcon(Icons.refresh), findsOneWidget);
    await tester.tap(find.byType(UpdateAllLanguagesButton));
    await tester.pump();

    expect(container.read(languageProvider('de')).downloadTimestamp,
        equals(DateTime.utc(2023, 10, 1)));
    // Snackbar visible?
    expect(find.text('Deutsch (de) ist nun auf dem aktuellsten Stand'),
        findsOneWidget);
  });

  // TODO Test correct handling / snackbar message when updates fail
}
