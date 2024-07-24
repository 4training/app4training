import 'package:app4training/data/app_language.dart';
import 'package:app4training/data/globals.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:app4training/widgets/download_language_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_language_test.dart';
import 'languages_test.dart';

class TestDownloadLanguageButton extends ConsumerWidget {
  final String languageCode;
  final bool highlight;
  const TestDownloadLanguageButton(this.languageCode,
      {this.highlight = false, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
        locale: ref.watch(appLanguageProvider).locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        scaffoldMessengerKey: ref.read(scaffoldMessengerKeyProvider),
        home: Scaffold(
            body: DownloadLanguageButton(languageCode, highlight: highlight)));
  }
}

void main() {
  testWidgets('Test DownloadLanguageButton', (WidgetTester tester) async {
    final ref = ProviderContainer(overrides: [
      appLanguageProvider.overrideWith(() => TestAppLanguage('de')),
      languageProvider
          .overrideWith(() => TestLanguageController(downloadedLanguages: [])),
    ]);

    await tester.pumpWidget(UncontrolledProviderScope(
        container: ref, child: const TestDownloadLanguageButton('en')));

    expect(find.byIcon(Icons.download), findsOneWidget);
    expect(find.byType(Container), findsNothing); // should not be highlighted
    expect(ref.read(languageProvider('en')).downloaded, false);

    await tester.tap(find.byType(DownloadLanguageButton));
    await tester.pump();
    expect(ref.read(languageProvider('en')).downloaded, true);
    // Snackbar visible?
    expect(find.text('Englisch (en) ist nun verfügbar'), findsOneWidget);
  });

  testWidgets('Test DownloadAllLanguagesButton', (WidgetTester tester) async {
    final ref = ProviderContainer(overrides: [
      appLanguageProvider.overrideWith(() => TestAppLanguage('de')),
      languageProvider
          .overrideWith(() => TestLanguageController(downloadedLanguages: []))
    ]);

    await tester.pumpWidget(UncontrolledProviderScope(
        container: ref,
        child: MaterialApp(
            locale: ref.read(appLanguageProvider).locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            scaffoldMessengerKey: ref.read(scaffoldMessengerKeyProvider),
            home: const Scaffold(body: DownloadAllLanguagesButton()))));

    expect(ref.read(languageProvider('ar')).downloaded, false);

    expect(find.byIcon(Icons.download), findsOneWidget);
    await tester.tap(find.byType(DownloadAllLanguagesButton));
    await tester.pump();

    expect(ref.read(languageProvider('ar')).downloaded, true);
    expect(ref.read(languageProvider('en')).downloaded, true);
    expect(ref.read(languageProvider('de')).downloaded, true);
    // Snackbar visible?
    expect(find.text('34 Sprachen heruntergeladen'), findsOneWidget);
  });

  testWidgets('Test highlighted DownloadLanguageButton',
      (WidgetTester tester) async {
    final ref = ProviderContainer(overrides: [
      appLanguageProvider.overrideWith(() => TestAppLanguage('de')),
      languageProvider
          .overrideWith(() => TestLanguageController(downloadedLanguages: [])),
    ]);

    await tester.pumpWidget(UncontrolledProviderScope(
        container: ref,
        child: const TestDownloadLanguageButton('en', highlight: true)));

    expect(find.byIcon(Icons.download), findsOneWidget);
    // Test the highlighting
    expect(find.byType(Container), findsOneWidget);

    // The rest should still function as normal
    await tester.tap(find.byType(DownloadLanguageButton));
    await tester.pump();
    expect(ref.read(languageProvider('en')).downloaded, true);
    // Snackbar visible?
    expect(find.text('Englisch (en) ist nun verfügbar'), findsOneWidget);
  });

  testWidgets('Test failing download', (WidgetTester tester) async {
    var throwingController = ThrowingDownloadAssetsController();
    final ref = ProviderContainer(overrides: [
      appLanguageProvider.overrideWith(() => TestAppLanguage('de')),
      languageProvider.overrideWith(
          () => LanguageController(assetsController: throwingController))
    ]);

    await tester.pumpWidget(UncontrolledProviderScope(
        container: ref, child: const TestDownloadLanguageButton('en')));

    await tester.tap(find.byType(DownloadLanguageButton));
    await tester.pump();
    expect(throwingController.startDownloadCalls, 1);
    expect(throwingController.clearAssetsCalled, true);
    expect(ref.read(languageProvider('en')).downloaded, false);
    // Snackbar visible?
    expect(find.textContaining('Download fehlgeschlagen'), findsOneWidget);
  });
  // TODO: test snackbar visibility duration
  // TODO: Test that there is a progress indicator while downloading
}
