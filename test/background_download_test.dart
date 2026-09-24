import 'package:app4training/background/background_task.dart';
import 'package:app4training/background/background_test.dart';
import 'package:app4training/data/globals.dart';
import 'package:app4training/data/updates.dart';
import 'package:file/memory.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'updates_test.dart';

/// Drive [backgroundDownload] with a fully faked container so we can assert
/// the AutomaticUpdates x connectivity decision matrix without any platform
/// channels or network access.
Future<({ProviderContainer ref, FakeLanguageDownloader downloader})> setup({
  required AutomaticUpdates automaticUpdates,
  required bool unmetered,
  List<String> langsWithUpdates = const ['de'],
}) async {
  SharedPreferences.setMockInitialValues({
    'automaticUpdates': automaticUpdates.name,
  });
  final prefs = await SharedPreferences.getInstance();
  final fileSystem = MemoryFileSystem();
  final downloader = FakeLanguageDownloader(fileSystem: fileSystem);

  final ref = ProviderContainer(
    overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      languageDownloaderProvider.overrideWithValue(downloader),
      connectivityServiceProvider.overrideWithValue(
        FakeConnectivityService(unmetered: unmetered),
      ),
      languageStatusProvider.overrideWith2(
        (langCode) => TestLanguageStatus(langWithUpdates: langsWithUpdates),
      ),
    ],
  );
  return (ref: ref, downloader: downloader);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AutomaticUpdates.never: never downloads', () {
    for (final unmetered in [true, false]) {
      test('unmetered=$unmetered', () async {
        final s = await setup(
          automaticUpdates: AutomaticUpdates.never,
          unmetered: unmetered,
        );
        await backgroundDownload(s.ref);
        expect(s.downloader.downloadCalls, 0);
      });
    }
  });

  group('AutomaticUpdates.requireConfirmation: never downloads', () {
    for (final unmetered in [true, false]) {
      test('unmetered=$unmetered, updatesAvailable stays true', () async {
        final s = await setup(
          automaticUpdates: AutomaticUpdates.requireConfirmation,
          unmetered: unmetered,
        );
        await backgroundDownload(s.ref);
        expect(s.downloader.downloadCalls, 0);
        // The foreground still needs to see that de has updates
        expect(s.ref.read(languageStatusProvider('de')).updatesAvailable, true);
      });
    }
  });

  group('AutomaticUpdates.onlyOnWifi: downloads only when unmetered', () {
    test('not unmetered -> no download', () async {
      final s = await setup(
        automaticUpdates: AutomaticUpdates.onlyOnWifi,
        unmetered: false,
      );
      await backgroundDownload(s.ref);
      expect(s.downloader.downloadCalls, 0);
    });

    test('unmetered -> downloads de', () async {
      final s = await setup(
        automaticUpdates: AutomaticUpdates.onlyOnWifi,
        unmetered: true,
      );
      await backgroundDownload(s.ref);
      expect(s.downloader.downloadedLangs, ['de']);
    });
  });

  group('AutomaticUpdates.yesAlways: downloads on any connection', () {
    for (final unmetered in [true, false]) {
      test('unmetered=$unmetered -> downloads de', () async {
        final s = await setup(
          automaticUpdates: AutomaticUpdates.yesAlways,
          unmetered: unmetered,
        );
        await backgroundDownload(s.ref);
        expect(s.downloader.downloadedLangs, ['de']);
      });
    }
  });

  test('Only languages with updatesAvailable are downloaded', () async {
    final s = await setup(
      automaticUpdates: AutomaticUpdates.yesAlways,
      unmetered: true,
      langsWithUpdates: ['de', 'fr'],
    );
    await backgroundDownload(s.ref);
    expect(s.downloader.downloadedLangs.toSet(), {'de', 'fr'});
    expect(s.downloader.downloadedLangs, isNot(contains('en')));
  });

  test('One failing download does not abort the whole run', () async {
    SharedPreferences.setMockInitialValues({
      'automaticUpdates': AutomaticUpdates.yesAlways.name,
    });
    final prefs = await SharedPreferences.getInstance();
    final fileSystem = MemoryFileSystem();
    // This downloader always throws
    final downloader = FakeLanguageDownloader(
      fileSystem: fileSystem,
      throwOnDownload: true,
    );

    final ref = ProviderContainer(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        languageDownloaderProvider.overrideWithValue(downloader),
        connectivityServiceProvider.overrideWithValue(
          FakeConnectivityService(unmetered: true),
        ),
        languageStatusProvider.overrideWith2(
          (langCode) => TestLanguageStatus(langWithUpdates: ['de', 'fr']),
        ),
      ],
    );

    // Should not throw even though every download() throws
    await backgroundDownload(ref);
    // It attempted both languages rather than bailing after the first failure
    expect(downloader.downloadCalls, 2);
  });
}
