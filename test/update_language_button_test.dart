import 'package:app4training/data/app_language.dart';
import 'package:app4training/data/globals.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/data/updates.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:app4training/widgets/update_language_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_language_test.dart';
import 'languages_test.dart';

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
    if (force) await deleteResources();
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
    final ref = ProviderContainer(overrides: [
      languageProvider.overrideWith(() => TestLanguageController()),
      languageStatusProvider.overrideWith(() => TestLanguageStatusNotifier()),
      appLanguageProvider.overrideWith(() => TestAppLanguage('de'))
    ]);

    await tester.pumpWidget(UncontrolledProviderScope(
        container: ref, child: const TestUpdateLanguageButton('en')));

    expect(find.byIcon(Icons.refresh), findsOneWidget);
    expect(ref.read(languageProvider('en')).downloaded, true);
    expect(ref.read(languageProvider('en')).downloadTimestamp,
        equals(DateTime.utc(2023, 1, 1)));
    expect(ref.read(languageStatusProvider('en')).updatesAvailable, false);

    await ref.read(languageStatusProvider('en').notifier).check();
    expect(ref.read(languageStatusProvider('en')).updatesAvailable, true);

    await tester.tap(find.byType(UpdateLanguageButton));
    await tester.pump();
    expect(ref.read(languageProvider('en')).downloadTimestamp,
        equals(DateTime.utc(2023, 10, 1)));
    expect(ref.read(languageStatusProvider('en')).updatesAvailable, false);
    // Snackbar visible?
    expect(find.text('Englisch (en) ist nun auf dem aktuellsten Stand'),
        findsOneWidget);
  });

  testWidgets('Test when download fails', (WidgetTester tester) async {
    var throwingController = ThrowingDownloadAssetsController();
    final ref = ProviderContainer(overrides: [
      appLanguageProvider.overrideWith(() => TestAppLanguage('de')),
      languageProvider.overrideWith(
          () => LanguageController(assetsController: throwingController)),
      languageStatusProvider.overrideWith(() => TestLanguageStatusNotifier())
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
/*  TODO
    expect(
        ref.read(languageStatusProvider('en')).updatesAvailable, true);*/
  });

  testWidgets('Test UpdateAllLanguagesButton: Updating 3 languages',
      (WidgetTester tester) async {
    final ref = ProviderContainer(overrides: [
      appLanguageProvider.overrideWith(() => TestAppLanguage('de')),
      languageProvider.overrideWith(() => TestLanguageController()),
      languageStatusProvider.overrideWith(() => TestLanguageStatusNotifier())
    ]);

    // Simulate that there are updates for these three languages available
    for (String languageCode in ['de', 'en', 'fr']) {
      await ref.read(languageStatusProvider(languageCode).notifier).check();
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
        equals(DateTime.utc(2023, 1, 1)));
    expect(ref.read(languageProvider('de')).downloadTimestamp,
        equals(DateTime.utc(2023, 10, 1)));
    expect(ref.read(languageStatusProvider('fr')).updatesAvailable, false);

    // Snackbar visible?
    expect(find.text('3 Sprachen aktualisiert'), findsOneWidget);
  });

  testWidgets('Test UpdateAllLanguagesButton: Updating one language',
      (WidgetTester tester) async {
    final ref = ProviderContainer(overrides: [
      appLanguageProvider.overrideWith(() => TestAppLanguage('de')),
      languageProvider.overrideWith(() => TestLanguageController()),
      languageStatusProvider.overrideWith(() => TestLanguageStatusNotifier())
    ]);
    await ref.read(languageStatusProvider('de').notifier).check();

    await tester.pumpWidget(UncontrolledProviderScope(
        container: ref, child: const TestUpdateAllLanguagesButton()));

    expect(find.byIcon(Icons.refresh), findsOneWidget);
    await tester.tap(find.byType(UpdateAllLanguagesButton));
    await tester.pump();

    expect(ref.read(languageProvider('de')).downloadTimestamp,
        equals(DateTime.utc(2023, 10, 1)));
    // Snackbar visible?
    expect(find.text('Deutsch (de) ist nun auf dem aktuellsten Stand'),
        findsOneWidget);
  });

  // TODO Test correct handling / snackbar message when updates fail
}
