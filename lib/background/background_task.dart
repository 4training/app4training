import 'dart:io';
import 'dart:ui';

import 'package:app4training/background/background_test.dart';
import 'package:app4training/data/connectivity_service.dart';
import 'package:app4training/data/globals.dart';
import 'package:app4training/data/language_downloader.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/data/updates.dart';
import 'package:dio/dio.dart';
import 'package:file/local.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

/// helper function for debugging: write a log message to a file.
/// Message gets appended to app_flutter/background.log in the app directory
/// TODO: Remove later
Future<void> writeLog(String message) async {
  try {
    debugPrint(message);
    final path = await getApplicationDocumentsDirectory();
    final file = File('${path.path}/background.log');
    await file.writeAsString(
      '${DateTime.now().toIso8601String()}: $message\n',
      mode: FileMode.append,
    );
  } catch (e) {
    debugPrint('Error writing message $message to file: $e');
  }
}

/// Entry point for the isolate for our background task
@pragma('vm:entry-point')
void backgroundTask() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == 'testTask') {
        // We're in the integration test
        await backgroundTestMain();
        // Send a message to indicate we're finished
        final sendPort = IsolateNameServer.lookupPortByName('test');
        if (sendPort != null) sendPort.send('success');
      } else {
        await backgroundMain();
      }
    } catch (e) {
      await writeLog('Unexpected error in background task: $e');
    }
    return Future.value(true);
  });
}

Future<void> backgroundMain() async {
  await writeLog("Background task is starting...");
  final prefs = await SharedPreferences.getInstance();
  final appDocsDir = await getApplicationDocumentsDirectory();
  final languageDownloader = LanguageDownloaderImpl(
    root: appDocsDir.path,
    dio: Dio(),
    fileSystem: const LocalFileSystem(),
  );

  final ref = ProviderContainer(
    overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      languageDownloaderProvider.overrideWithValue(languageDownloader),
      connectivityServiceProvider.overrideWithValue(ConnectivityServiceImpl()),
    ],
  );

  // Phase 1: check every downloaded language for updates
  await backgroundCheck(ref);

  // Phase 2: download the languages that have updates, gated by the user's
  // AutomaticUpdates setting and (for onlyOnWifi) the current connection type
  await backgroundDownload(ref);
}

/// Download the languages that have updates available, honoring the user's
/// [AutomaticUpdates] setting and connectivity. Assumes [backgroundCheck] has
/// already run so that `updatesAvailable` reflects the remote state.
///
/// | AutomaticUpdates    | metered      | unmetered (WiFi/ethernet) |
/// | ------------------- | ------------ | ------------------------- |
/// | never               | no download  | no download               |
/// | requireConfirmation | no download  | no download               |
/// | onlyOnWifi          | no download  | download                  |
/// | yesAlways           | download     | download                  |
Future<void> backgroundDownload(ProviderContainer ref) async {
  // Read the setting from the isolate's own SharedPreferences instance
  final automaticUpdates = ref.read(automaticUpdatesProvider);
  await writeLog('AutomaticUpdates setting: ${automaticUpdates.name}');

  switch (automaticUpdates) {
    case AutomaticUpdates.never:
    case AutomaticUpdates.requireConfirmation:
      // Never auto-download. requireConfirmation leaves updatesAvailable set
      // so the foreground can surface it and let the user confirm.
      return;
    case AutomaticUpdates.onlyOnWifi:
      if (!await ref.read(connectivityServiceProvider).isUnmetered()) {
        await writeLog('onlyOnWifi but connection is metered: skipping');
        return;
      }
    case AutomaticUpdates.yesAlways:
      // The periodic task's NetworkType.connected constraint already
      // guarantees some connection, so download regardless of its type.
      break;
  }

  for (String languageCode in ref.read(availableLanguagesProvider)) {
    if (!ref.read(languageStatusProvider(languageCode)).updatesAvailable) {
      continue;
    }
    try {
      await writeLog('Downloading update for $languageCode in background');
      await ref.read(languageDownloaderProvider).download(languageCode);
      // Re-downloading refreshes the download timestamp; re-reading the status
      // lets LanguageStatusNotifier.build() reset updatesAvailable to false.
      ref.invalidate(languageStatusProvider(languageCode));
    } catch (e) {
      // Don't let one language's failure abort the whole run
      await writeLog('Error downloading $languageCode in background: $e');
    }
  }
}

/// For the integration test: Simulates that we have
/// German downloaded
Future<void> backgroundTestMain() async {
  await writeLog("Background task is starting in test mode...");
  final prefs = await SharedPreferences.getInstance();
  var fileSystem = await createTestFileSystem();

  final ref = ProviderContainer(
    overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      fileSystemProvider.overrideWith((ref) => fileSystem),
      languageDownloaderProvider.overrideWithValue(
        FakeLanguageDownloader(fileSystem: fileSystem),
      ),
      // Fake connectivity so the download decision is deterministic in the
      // integration test (no real platform channel in the isolate).
      connectivityServiceProvider.overrideWithValue(
        FakeConnectivityService(unmetered: true),
      ),
      // Fake the update check so it doesn't hit the live (rate-limited) GitHub
      // API - check() still persists a fresh lastChecked timestamp, which is
      // what the foreground isolate uses to detect background activity.
      httpClientProvider.overrideWithValue(fakeNoUpdatesClient()),
    ],
  );
  // Same two-phase flow as backgroundMain(): check, then settings-gated download
  await backgroundCheck(ref);
  await backgroundDownload(ref);
}

/// Check for updates for all downloaded languages
Future<void> backgroundCheck(ProviderContainer ref) async {
  for (String languageCode in ref.read(availableLanguagesProvider)) {
    await ref.read(languageProvider(languageCode).notifier).lazyInit();
    if (!ref.read(languageProvider(languageCode)).downloaded) {
      await writeLog('Checking $languageCode... not downloaded');
      continue;
    } else {
      await writeLog('Checking $languageCode... downloaded');
      // Check for updates
      final status = ref.read(languageStatusProvider(languageCode));
      if (status.updatesAvailable) continue;
      int updates =
          await ref.read(languageStatusProvider(languageCode).notifier).check();
      if (updates == apiRateLimitExceeded) break;
      await writeLog('Checked $languageCode for updates: $updates');
    }
  }
}
