import 'package:app4training/background/background_task.dart';
import 'package:app4training/background/background_test.dart';
import 'package:app4training/data/globals.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/data/updates.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'languages_test.dart';
import 'updates_test.dart';

/// German is downloaded; the GitHub API reports [remoteUpdates] new commits
Future<({ProviderContainer ref, FakeLanguageDownloader downloader})> setup({
  required AutomaticUpdates automaticUpdates,
  int remoteUpdates = 1,
  bool unmetered = true,
}) async {
  SharedPreferences.setMockInitialValues({
    'checkFrequency': CheckFrequency.daily.name,
    'automaticUpdates': automaticUpdates.name,
  });
  final prefs = await SharedPreferences.getInstance();
  final fileSystem = await createBasicFileSystem(['de']);
  final downloader = FakeLanguageDownloader(fileSystem: fileSystem);

  final ref = ProviderContainer(
    overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      fileSystemProvider.overrideWith((ref) => fileSystem),
      languageDownloaderProvider.overrideWithValue(downloader),
      connectivityServiceProvider.overrideWithValue(
        FakeConnectivityService(unmetered: unmetered),
      ),
      httpClientProvider.overrideWithValue(
        MockClient((request) async => fakeResponseNUpdates(remoteUpdates)),
      ),
    ],
  );
  return (ref: ref, downloader: downloader);
}

/// A run that is due: a day after German was downloaded
DateTime get dueRun => DateTime.now().toUtc().add(const Duration(days: 2));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('iOS: updates found -> downloads are deferred to a processing task '
      'instead of running in the refresh task', () async {
    final s = await setup(automaticUpdates: AutomaticUpdates.yesAlways);
    int deferred = 0;
    await backgroundRun(
      s.ref,
      now: dueRun,
      deferDownload: () async => deferred++,
    );
    expect(deferred, 1);
    expect(s.downloader.downloadCalls, 0);
  });

  for (final setting in [
    AutomaticUpdates.never,
    AutomaticUpdates.requireConfirmation,
  ]) {
    test('iOS: ${setting.name} -> no processing task is scheduled', () async {
      final s = await setup(automaticUpdates: setting);
      int deferred = 0;
      await backgroundRun(
        s.ref,
        now: dueRun,
        deferDownload: () async => deferred++,
      );
      expect(deferred, 0);
      expect(s.downloader.downloadCalls, 0);
    });
  }

  test('iOS: no updates found -> no processing task is scheduled', () async {
    final s = await setup(
      automaticUpdates: AutomaticUpdates.yesAlways,
      remoteUpdates: 0,
    );
    int deferred = 0;
    await backgroundRun(
      s.ref,
      now: dueRun,
      deferDownload: () async => deferred++,
    );
    expect(deferred, 0);
  });

  test('iOS: onlyOnWifi on mobile data still schedules the processing task: '
      'it runs later (often on WiFi) and re-checks the connection', () async {
    final s = await setup(
      automaticUpdates: AutomaticUpdates.onlyOnWifi,
      unmetered: false,
    );
    int deferred = 0;
    await backgroundRun(
      s.ref,
      now: dueRun,
      deferDownload: () async => deferred++,
    );
    expect(deferred, 1);
    expect(s.downloader.downloadCalls, 0);
  });

  test(
    'Android: without deferDownload, updates are downloaded right away',
    () async {
      final s = await setup(automaticUpdates: AutomaticUpdates.yesAlways);
      await backgroundRun(s.ref, now: dueRun);
      expect(s.downloader.downloadedLangs, ['de']);
    },
  );
}
