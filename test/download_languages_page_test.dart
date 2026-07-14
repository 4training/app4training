import 'dart:async';

import 'package:app4training/data/app_language.dart';
import 'package:app4training/data/globals.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/data/updates.dart';
import 'package:app4training/l10n/generated/app_localizations.dart';
import 'package:app4training/l10n/generated/app_localizations_de.dart';
import 'package:app4training/l10n/generated/app_localizations_en.dart';
import 'package:app4training/routes/onboarding/download_languages_page.dart';
import 'package:app4training/routes/routes.dart';
import 'package:app4training/widgets/download_language_button.dart';
import 'package:app4training/widgets/languages_table.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_language_test.dart';
import 'download_language_button_test.dart';
import 'languages_test.dart';
import 'routes_test.dart';
import 'updates_test.dart';

/// Test DownloadLanguagesPage
class TestDownloadLanguagesPage extends ConsumerWidget {
  final TestObserver navigatorObserver;

  const TestDownloadLanguagesPage(this.navigatorObserver, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      locale: ref.watch(appLanguageProvider).locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      onGenerateRoute: (settings) => generateRoutes(settings),
      navigatorObservers: [navigatorObserver],
      scaffoldMessengerKey: ref.read(scaffoldMessengerKeyProvider),
      home: const DownloadLanguagesPage(),
    );
  }
}

void main() {
  testWidgets('DownloadLanguagesPage basic test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final testObserver = TestObserver();
    final ref = ProviderContainer(
      overrides: [
        appLanguageProvider.overrideWith(() => TestAppLanguage('en')),
        languageProvider.overrideWith2(
          (languageCode) => TestLanguageController(downloadedLanguages: []),
        ),
        sharedPrefsProvider.overrideWith((ref) => prefs),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: ref,
        child: TestDownloadLanguagesPage(testObserver),
      ),
    );

    expect(find.text(AppLocalizationsEn().downloadLanguages), findsOneWidget);
    expect(
      find.text(AppLocalizationsEn().downloadLanguagesExplanation),
      findsOneWidget,
    );
    expect(find.byType(LanguagesTable), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNWidgets(2));

    // Press the continue button
    expect(testObserver.replacedRoutes, isEmpty);
    await tester.tap(
      find.widgetWithText(ElevatedButton, AppLocalizationsEn().continueText),
    );
    await tester.pump();

    // Now we see the MissingAppLanguageDialog and close it
    expect(find.byType(MissingAppLanguageDialog), findsOneWidget);
    await tester.tap(
      find.widgetWithText(TextButton, AppLocalizationsEn().gotit),
    );
    await tester.pump();
    expect(find.byType(MissingAppLanguageDialog), findsNothing);

    // Simulate downloading English
    await ref.read(languageProvider('en').notifier).download();
    await tester.pump();

    // Now we press the continue button again - this time it should continue
    await tester.tap(
      find.widgetWithText(ElevatedButton, AppLocalizationsEn().continueText),
    );
    await tester.pump();
    // checkFrequency is unset (fresh onboarding) -> continue to third step
    expect(listEquals(testObserver.replacedRoutes, ['/onboarding/3']), isTrue);
  });

  testWidgets('Test DownloadLanguagesPage back button in German', (
    WidgetTester tester,
  ) async {
    final testObserver = TestObserver();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLanguageProvider.overrideWith(() => TestAppLanguage('de')),
          languageStatusProvider.overrideWith2(
            (languageCode) => TestLanguageStatus(),
          ),
        ],
        child: TestDownloadLanguagesPage(testObserver),
      ),
    );

    // Check that the page is translated
    expect(find.text(AppLocalizationsDe().downloadLanguages), findsOneWidget);
    expect(
      find.text(AppLocalizationsDe().downloadLanguagesExplanation),
      findsOneWidget,
    );

    // Click the back button
    expect(testObserver.replacedRoutes, isEmpty);
    await tester.tap(
      find.widgetWithText(ElevatedButton, AppLocalizationsDe().back),
    );
    await tester.pump();
    expect(listEquals(testObserver.replacedRoutes, ['/onboarding/1']), isTrue);
  });

  testWidgets('Download-all progress is shown on the onboarding screen', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final gates = {
      for (final code in ['de', 'en', 'fr']) code: Completer<void>()
    };
    final ref = ProviderContainer(
      overrides: [
        appLanguageProvider.overrideWith(() => TestAppLanguage('en')),
        availableLanguagesProvider.overrideWithValue(['de', 'en', 'fr']),
        languageProvider.overrideWith2(
          (languageCode) => GatedDownloadLanguageController(gates),
        ),
        languageStatusProvider.overrideWith2(
          (languageCode) => TestLanguageStatus(),
        ),
        sharedPrefsProvider.overrideWith((ref) => prefs),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: ref,
        child: TestDownloadLanguagesPage(TestObserver()),
      ),
    );
    final l10n = AppLocalizationsEn();

    await tester.tap(find.byType(DownloadAllLanguagesButton));
    await tester.pump();
    expect(find.text(l10n.downloadProgress(0, 3)), findsOneWidget);

    // One pump lets the download finish, the next draws the new caption
    gates['de']!.complete();
    await tester.pump();
    await tester.pump();
    expect(find.text(l10n.downloadProgress(1, 3)), findsOneWidget);

    gates['en']!.complete();
    gates['fr']!.complete();
    await tester.pump();
    await tester.pump();
    expect(find.text(l10n.downloadedNLanguages(3)), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('Test skipping third onboarding step', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'checkFrequency': 'weekly'});
    final prefs = await SharedPreferences.getInstance();
    final testObserver = TestObserver();
    final ref = ProviderContainer(
      overrides: [
        appLanguageProvider.overrideWith(() => TestAppLanguage('de')),
        languageProvider.overrideWith2(
          (languageCode) => TestLanguageController(downloadedLanguages: []),
        ),
        sharedPrefsProvider.overrideWith((ref) => prefs),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: ref,
        child: TestDownloadLanguagesPage(testObserver),
      ),
    );

    await ref.read(languageProvider('en').notifier).download();
    await tester.pump();
    await tester.tap(
      find.widgetWithText(ElevatedButton, AppLocalizationsDe().continueText),
    );
    await tester.pump();

    // We see MissingAppLanguageDialog and close it
    expect(find.byType(MissingAppLanguageDialog), findsOneWidget);
    await tester.tap(
      find.widgetWithText(TextButton, AppLocalizationsDe().gotit),
    );
    await tester.pump();
    expect(find.byType(MissingAppLanguageDialog), findsNothing);

    // Now we download German and continue - this time it should work
    await ref.read(languageProvider('de').notifier).download();
    await tester.pump();
    expect(testObserver.replacedRoutes, isEmpty);
    await tester.tap(
      find.widgetWithText(ElevatedButton, AppLocalizationsDe().continueText),
    );
    await tester.pump();

    // Testing getNextRoute()
    expect(listEquals(testObserver.replacedRoutes, ['/home']), isTrue);
  });
}
