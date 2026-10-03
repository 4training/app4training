import 'package:app4training/data/app_language.dart';
import 'package:app4training/data/globals.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/data/updates.dart';
import 'package:app4training/l10n/generated/app_localizations.dart';
import 'package:app4training/l10n/generated/app_localizations_en.dart';
import 'package:app4training/widgets/confirm_updates_prompt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_language_test.dart';
import 'languages_test.dart';
import 'updates_test.dart';

class TestConfirmUpdatesPrompt extends ConsumerWidget {
  const TestConfirmUpdatesPrompt({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      locale: ref.read(appLanguageProvider).locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      scaffoldMessengerKey: ref.read(scaffoldMessengerKeyProvider),
      home: const Scaffold(body: ConfirmUpdatesPrompt()),
    );
  }
}

Future<ProviderContainer> makeRef(String automaticUpdates) async {
  SharedPreferences.setMockInitialValues({
    'automaticUpdates': automaticUpdates,
  });
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [
      appLanguageProvider.overrideWith(() => TestAppLanguage('en')),
      languageProvider.overrideWith2((langCode) => TestLanguageController()),
      sharedPrefsProvider.overrideWith((ref) => prefs),
      httpClientProvider.overrideWith((ref) => mockReturnTwoUpdates()),
    ],
  );
}

void main() {
  testWidgets('Prompt hidden when no updates available', (tester) async {
    final ref = await makeRef('requireConfirmation');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: ref,
        child: const TestConfirmUpdatesPrompt(),
      ),
    );

    expect(find.text(AppLocalizationsEn().downloadUpdatesNow), findsNothing);
  });

  testWidgets('Prompt hidden under yesAlways even with updates', (
    tester,
  ) async {
    final ref = await makeRef('yesAlways');
    await ref.read(languageStatusProvider('de').notifier).check();
    expect(ref.read(updatesAvailableProvider), true);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: ref,
        child: const TestConfirmUpdatesPrompt(),
      ),
    );

    expect(find.text(AppLocalizationsEn().downloadUpdatesNow), findsNothing);
  });

  testWidgets('Prompt shown under requireConfirmation with updates', (
    tester,
  ) async {
    final ref = await makeRef('requireConfirmation');
    await ref.read(languageStatusProvider('de').notifier).check();
    expect(ref.read(updatesNeedConfirmationProvider), true);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: ref,
        child: const TestConfirmUpdatesPrompt(),
      ),
    );

    expect(find.text(AppLocalizationsEn().downloadUpdatesNow), findsOneWidget);
  });

  testWidgets('Confirming downloads updates and dismisses the prompt', (
    tester,
  ) async {
    final ref = await makeRef('requireConfirmation');
    await ref.read(languageStatusProvider('de').notifier).check();
    expect(ref.read(languageStatusProvider('de')).updatesAvailable, true);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: ref,
        child: const TestConfirmUpdatesPrompt(),
      ),
    );

    await tester.tap(find.text(AppLocalizationsEn().downloadUpdatesNow));
    await tester.pump();

    // de got re-downloaded -> its updatesAvailable resets
    expect(
      ref
          .read(languageProvider('de'))
          .downloadTimestamp
          .compareTo(DateTime.utc(2023)),
      greaterThan(0),
    );
    expect(ref.read(languageStatusProvider('de')).updatesAvailable, false);
    // The prompt should now be gone (no more confirmation needed)
    expect(ref.read(updatesNeedConfirmationProvider), false);
    expect(find.text(AppLocalizationsEn().downloadUpdatesNow), findsNothing);
  });
}
