import 'dart:async';

import 'package:app4training/background/background_test.dart';
import 'package:app4training/data/app_language.dart';
import 'package:app4training/data/globals.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/l10n/generated/app_localizations.dart';
import 'package:app4training/l10n/generated/app_localizations_de.dart';
import 'package:app4training/widgets/download_language_button.dart';
import 'package:file/memory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_language_test.dart';
import 'languages_test.dart';

/// Lets the test decide when the download of each language finishes
class GatedDownloadLanguageController extends TestLanguageController {
  GatedDownloadLanguageController(this.gates) : super(downloadedLanguages: []);
  final Map<String, Completer<void>> gates;

  @override
  Future<bool> download() async {
    await gates[languageCode]!.future;
    return super.download();
  }
}

class TestDownloadLanguageButton extends ConsumerWidget {
  final String languageCode;
  final bool highlight;
  const TestDownloadLanguageButton(
    this.languageCode, {
    this.highlight = false,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      locale: ref.watch(appLanguageProvider).locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      scaffoldMessengerKey: ref.read(scaffoldMessengerKeyProvider),
      home: Scaffold(
        body: DownloadLanguageButton(languageCode, highlight: highlight),
      ),
    );
  }
}

void main() {
  testWidgets('Test DownloadLanguageButton', (WidgetTester tester) async {
    final ref = ProviderContainer(
      overrides: [
        appLanguageProvider.overrideWith(() => TestAppLanguage('de')),
        languageProvider.overrideWith2(
          (langCode) => TestLanguageController(downloadedLanguages: []),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: ref,
        child: const TestDownloadLanguageButton('en'),
      ),
    );

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
    final ref = ProviderContainer(
      overrides: [
        appLanguageProvider.overrideWith(() => TestAppLanguage('de')),
        languageProvider.overrideWith2(
          (langCode) => TestLanguageController(downloadedLanguages: []),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: ref,
        child: MaterialApp(
          locale: ref.read(appLanguageProvider).locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          scaffoldMessengerKey: ref.read(scaffoldMessengerKeyProvider),
          home: const Scaffold(body: DownloadAllLanguagesButton()),
        ),
      ),
    );

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

  testWidgets('DownloadAllLanguagesButton shows how far the batch is', (
    WidgetTester tester,
  ) async {
    final gates = {
      for (final code in ['de', 'en', 'fr']) code: Completer<void>(),
    };
    final ref = ProviderContainer(
      overrides: [
        appLanguageProvider.overrideWith(() => TestAppLanguage('de')),
        availableLanguagesProvider.overrideWithValue(['de', 'en', 'fr']),
        languageProvider.overrideWith2(
          (langCode) => GatedDownloadLanguageController(gates),
        ),
      ],
    );
    final l10n = AppLocalizationsDe();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: ref,
        child: MaterialApp(
          locale: ref.read(appLanguageProvider).locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          scaffoldMessengerKey: ref.read(scaffoldMessengerKeyProvider),
          home: const Scaffold(body: DownloadAllLanguagesButton()),
        ),
      ),
    );

    CircularProgressIndicator indicator() =>
        tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );

    // Let a released download finish (first pump) and draw the caption that
    // its setState() asked for (second pump)
    Future<void> finish(String code) async {
      gates[code]!.complete();
      await tester.pump();
      await tester.pump();
    }

    await tester.tap(find.byType(DownloadAllLanguagesButton));
    await tester.pump();
    expect(find.text(l10n.downloadProgress(0, 3)), findsOneWidget);
    expect(indicator().value, 0);

    await finish('de');
    expect(find.text(l10n.downloadProgress(1, 3)), findsOneWidget);
    expect(indicator().value, closeTo(1 / 3, 0.001));

    await finish('en');
    expect(find.text(l10n.downloadProgress(2, 3)), findsOneWidget);
    expect(indicator().value, closeTo(2 / 3, 0.001));

    // Once the last one is in, the button is back and the summary shows
    await finish('fr');
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.download), findsOneWidget);
    expect(find.text('3 Sprachen heruntergeladen'), findsOneWidget);
  });

  testWidgets('Test highlighted DownloadLanguageButton', (
    WidgetTester tester,
  ) async {
    final ref = ProviderContainer(
      overrides: [
        appLanguageProvider.overrideWith(() => TestAppLanguage('de')),
        languageProvider.overrideWith2(
          (langCode) => TestLanguageController(downloadedLanguages: []),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: ref,
        child: const TestDownloadLanguageButton('en', highlight: true),
      ),
    );

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
    final fileSystem = MemoryFileSystem();
    final fakeDownloader = FakeLanguageDownloader(
      fileSystem: fileSystem,
      throwOnDownload: true,
    );
    final ref = ProviderContainer(
      overrides: [
        appLanguageProvider.overrideWith(() => TestAppLanguage('de')),
        fileSystemProvider.overrideWith((ref) => fileSystem),
        languageDownloaderProvider.overrideWithValue(fakeDownloader),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: ref,
        child: const TestDownloadLanguageButton('en'),
      ),
    );

    await tester.tap(find.byType(DownloadLanguageButton));
    await tester.pump();
    expect(fakeDownloader.downloadCalls, 1);
    expect(ref.read(languageProvider('en')).downloaded, false);
    // Snackbar visible?
    expect(find.textContaining('Download fehlgeschlagen'), findsOneWidget);
  });
  // TODO: test snackbar visibility duration
  // TODO: Test that there is a progress indicator while downloading
}
