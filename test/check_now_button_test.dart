import 'package:app4training/data/app_language.dart';
import 'package:app4training/data/globals.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/data/updates.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:app4training/widgets/check_now_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations_de.dart';

import 'app_language_test.dart';
import 'delete_language_button_test.dart';

int countCheckCalled = 0;

/// For testing: first there are no updates available.
/// The constructor takes the value that check() should return later.
class TestLanguageStatusNotifier extends LanguageStatusNotifier {
  final int _checkReturnCode;
  TestLanguageStatusNotifier(this._checkReturnCode);

  @override
  LanguageStatus build(String arg) {
    return LanguageStatus(
        false, DateTime.utc(2023, 1, 1), DateTime.utc(2023, 1, 1));
  }

  @override
  Future<int> check() async {
    countCheckCalled++;
    if (_checkReturnCode >= 0) {
      state = LanguageStatus(_checkReturnCode > 0, state.downloadTimestamp,
          DateTime.now().toUtc());
    }
    return _checkReturnCode;
  }
}

class TestCheckNowButton extends ConsumerWidget {
  const TestCheckNowButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
        locale: ref.watch(appLanguageProvider).locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        scaffoldMessengerKey: ref.read(scaffoldMessengerKeyProvider),
        home: const Scaffold(body: CheckNowButton(buttonText: 'Check')));
  }
}

void main() {
  testWidgets('Test when no updates are available',
      (WidgetTester tester) async {
    final ref = ProviderContainer(overrides: [
      appLanguageProvider.overrideWith(() => TestAppLanguage('de')),
      languageProvider.overrideWith(() => TestLanguageController()),
      languageStatusProvider.overrideWith(() => TestLanguageStatusNotifier(0))
    ]);

    await tester.pumpWidget(UncontrolledProviderScope(
        container: ref, child: const TestCheckNowButton()));

    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(ref.read(languageStatusProvider('en')).updatesAvailable, false);

    await tester.tap(find.byType(CheckNowButton));
    await tester.pump();
    expect(ref.read(languageStatusProvider('en')).updatesAvailable, false);
    // snackbar correct?
    expect(find.text('Alle Sprachen sind bereits aktuell'), findsOneWidget);
  });

  testWidgets('Test with 2 updates available in each language',
      (WidgetTester tester) async {
    countCheckCalled = 0;
    final ref = ProviderContainer(overrides: [
      appLanguageProvider.overrideWith(() => TestAppLanguage('de')),
      languageProvider.overrideWith(() => TestLanguageController()),
      languageStatusProvider.overrideWith(() => TestLanguageStatusNotifier(2))
    ]);

    await tester.pumpWidget(UncontrolledProviderScope(
        container: ref, child: const TestCheckNowButton()));

    expect(ref.read(languageStatusProvider('en')).updatesAvailable, false);
    expect(ref.read(languageStatusProvider('en')).lastCheckedTimestamp,
        equals(DateTime.utc(2023, 1, 1)));

    await tester.tap(find.byType(CheckNowButton));
    await tester.pump();
    expect(ref.read(languageStatusProvider('en')).updatesAvailable, true);
    expect(ref.read(languageStatusProvider('en')).lastCheckedTimestamp,
        isNot(equals(DateTime.utc(2023, 1, 1))));
    // snackbar correct?
    expect(find.text('Updates für 34 Sprachen verfügbar'), findsOneWidget);
    expect(countCheckCalled, countAvailableLanguages);
  });

  testWidgets('Test that we ran into Github API rate limit',
      (WidgetTester tester) async {
    countCheckCalled = 0;
    final ref = ProviderContainer(overrides: [
      appLanguageProvider.overrideWith(() => TestAppLanguage('de')),
      languageProvider.overrideWith(() => TestLanguageController()),
      languageStatusProvider
          .overrideWith(() => TestLanguageStatusNotifier(apiRateLimitExceeded))
    ]);

    await tester.pumpWidget(UncontrolledProviderScope(
        container: ref, child: const TestCheckNowButton()));

    expect(ref.read(languageStatusProvider('en')).updatesAvailable, false);
    expect(ref.read(languageStatusProvider('en')).lastCheckedTimestamp,
        equals(DateTime.utc(2023, 1, 1)));

    await tester.tap(find.byType(CheckNowButton));
    await tester.pump();
    expect(ref.read(languageStatusProvider('en')).updatesAvailable, false);
    expect(ref.read(languageStatusProvider('en')).lastCheckedTimestamp,
        equals(DateTime.utc(2023, 1, 1)));
    // snackbar correct?
    expect(
        find.text(AppLocalizationsDe().checkingUpdatesLimit), findsOneWidget);
    // Verify that we skipped the rest after the first error of this kind
    expect(countCheckCalled, 1);
  });

  testWidgets('Test unknown error while checking for updates',
      (WidgetTester tester) async {
    countCheckCalled = 0;
    final ref = ProviderContainer(overrides: [
      appLanguageProvider.overrideWith(() => TestAppLanguage('de')),
      languageProvider.overrideWith(() => TestLanguageController()),
      languageStatusProvider.overrideWith(() => TestLanguageStatusNotifier(-1))
    ]);

    await tester.pumpWidget(UncontrolledProviderScope(
        container: ref, child: const TestCheckNowButton()));

    expect(ref.read(languageStatusProvider('en')).updatesAvailable, false);
    expect(ref.read(languageStatusProvider('en')).lastCheckedTimestamp,
        equals(DateTime.utc(2023, 1, 1)));

    await tester.tap(find.byType(CheckNowButton));
    await tester.pump();
    expect(ref.read(languageStatusProvider('en')).updatesAvailable, false);
    expect(ref.read(languageStatusProvider('en')).lastCheckedTimestamp,
        equals(DateTime.utc(2023, 1, 1)));
    // snackbar correct?
    expect(
        find.text(AppLocalizationsDe().checkingUpdatesError), findsOneWidget);
    expect(countCheckCalled, countAvailableLanguages);
  });
}
