import 'package:app4training/data/app_language.dart';
import 'package:app4training/data/globals.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/data/updates.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:app4training/widgets/update_language_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_language_test.dart';
import 'languages_test.dart';
import 'updates_test.dart' hide TestLanguageStatus;

class TestUpdateLanguageButton extends ConsumerWidget {
  final String languageCode;

  const TestUpdateLanguageButton(this.languageCode, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
        locale: ref.watch(appLanguageProvider).locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        scaffoldMessengerKey: ref.read(scaffoldMessengerKeyProvider),
        home: Scaffold(body: UpdateLanguageButton(languageCode)));
  }
}

class TestUpdateAllLanguagesButton extends ConsumerWidget {
  const TestUpdateAllLanguagesButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
        locale: ref.read(appLanguageProvider).locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        scaffoldMessengerKey: ref.read(scaffoldMessengerKeyProvider),
        home: const Scaffold(body: UpdateAllLanguagesButton()));
  }
}

void main() {
  testWidgets('Test UpdateLanguageButton', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final ref = ProviderContainer(overrides: [
      languageProvider.overrideWith(() => TestLanguageController()),
      appLanguageProvider.overrideWith(() => TestAppLanguage('de')),
      sharedPrefsProvider.overrideWith((ref) => prefs),
      httpClientProvider.overrideWith((ref) => mockReturnTwoUpdates())
    ]);

    await tester.pumpWidget(UncontrolledProviderScope(
        container: ref, child: const TestUpdateLanguageButton('en')));

    expect(find.byIcon(Icons.refresh), findsOneWidget);
    expect(ref.read(languageProvider('en')).downloaded, true);
    final firstTimestamp = ref.read(languageProvider('en')).downloadTimestamp;
    expect(firstTimestamp, equals(DateTime.utc(2023)));
    expect(ref.read(languageStatusProvider('en')).updatesAvailable, false);

    await ref.read(languageStatusProvider('en').notifier).check();
    await ref.read(languageStatusProvider('de').notifier).check();
    await ref.read(languageStatusProvider('fr').notifier).check();
    expect(ref.read(languageStatusProvider('en')).updatesAvailable, true);
    expect(ref.read(languageStatusProvider('de')).updatesAvailable, true);
    expect(ref.read(languageStatusProvider('fr')).updatesAvailable, true);

    await tester.tap(find.byType(UpdateLanguageButton));
    await tester.pump();
    final secondTimestamp = ref.read(languageProvider('en')).downloadTimestamp;
    expect(secondTimestamp.compareTo(firstTimestamp), greaterThan(0));
    expect(ref.read(languageStatusProvider('en')).updatesAvailable, false);
    // Snackbar visible?
    expect(find.text('Englisch (en) ist nun auf dem aktuellsten Stand'),
        findsOneWidget);
  });

  testWidgets('Test when download fails', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var throwingController = ThrowingDownloadAssetsController();
    final ref = ProviderContainer(overrides: [
      appLanguageProvider.overrideWith(() => TestAppLanguage('de')),
      languageProvider.overrideWith(
          () => LanguageController(assetsController: throwingController)),
      sharedPrefsProvider.overrideWith((ref) => prefs),
      httpClientProvider.overrideWith((ref) => mockReturnTwoUpdates())
    ]);

    await tester.pumpWidget(UncontrolledProviderScope(
        container: ref, child: const TestUpdateLanguageButton('en')));

    await ref.read(languageStatusProvider('en').notifier).check();
    expect(ref.read(languageStatusProvider('en')).updatesAvailable, true);

    await tester.tap(find.byType(UpdateLanguageButton));
    await tester.pump();
    expect(throwingController.startDownloadCalled, true);
    expect(throwingController.clearAssetsCalled, true);
    // Snackbar visible?
    expect(
        find.textContaining('Aktualisierung fehlgeschlagen.'), findsOneWidget);
    expect(ref.read(languageProvider('en')).downloaded, false);
    expect(ref.read(languageStatusProvider('en')).updatesAvailable, false);
  });

  testWidgets('Test UpdateAllLanguagesButton: Updating 3 languages',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final ref = ProviderContainer(overrides: [
      appLanguageProvider.overrideWith(() => TestAppLanguage('de')),
      languageProvider.overrideWith(() => TestLanguageController()),
      sharedPrefsProvider.overrideWith((ref) => prefs),
      httpClientProvider.overrideWith((ref) => mockReturnTwoUpdates())
    ]);

    expect(ref.read(updatesAvailableProvider), false);
    // Simulate that there are updates for these three languages available
    for (String languageCode in ['de', 'en', 'fr']) {
      expect(
          await ref.read(languageStatusProvider(languageCode).notifier).check(),
          2);
    }
    expect(ref.read(updatesAvailableProvider), true);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: ref, child: const TestUpdateAllLanguagesButton()));

    expect(find.byIcon(Icons.refresh), findsOneWidget);
    await tester.tap(find.byType(UpdateAllLanguagesButton));
    await tester.pump();

    expect(ref.read(updatesAvailableProvider), false);
    expect(find.byIcon(Icons.refresh), findsNothing);
    expect(ref.read(languageProvider('ar')).downloadTimestamp,
        equals(DateTime.utc(2023)));
    expect(
        ref
            .read(languageProvider('de'))
            .downloadTimestamp
            .compareTo(DateTime.utc(2023)),
        greaterThan(0));
    expect(ref.read(languageStatusProvider('fr')).updatesAvailable, false);

    await tester.pumpAndSettle();
    // Snackbar visible?
    expect(find.text('3 Sprachen aktualisiert'), findsOneWidget);
  });

  testWidgets('Test UpdateAllLanguagesButton: Updating one language',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final ref = ProviderContainer(overrides: [
      appLanguageProvider.overrideWith(() => TestAppLanguage('de')),
      languageProvider.overrideWith(() => TestLanguageController()),
      sharedPrefsProvider.overrideWith((ref) => prefs),
      httpClientProvider.overrideWith((ref) => mockReturnTwoUpdates())
    ]);
    expect(ref.read(languageProvider('de')).downloadTimestamp,
        equals(DateTime.utc(2023)));
    await ref.read(languageStatusProvider('de').notifier).check();

    await tester.pumpWidget(UncontrolledProviderScope(
        container: ref, child: const TestUpdateAllLanguagesButton()));

    expect(find.byIcon(Icons.refresh), findsOneWidget);
    await tester.tap(find.byType(UpdateAllLanguagesButton));
    await tester.pump();

    expect(
        ref
            .read(languageProvider('de'))
            .downloadTimestamp
            .compareTo(DateTime.utc(2023)),
        greaterThan(0));
    // Snackbar visible?
    expect(find.text('Deutsch (de) ist nun auf dem aktuellsten Stand'),
        findsOneWidget);
  });

  // TODO Test correct handling / snackbar message when updates fail
}
