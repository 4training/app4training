import 'dart:io';
import 'dart:ui';

import 'package:app4training/data/globals.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/data/updates.dart';
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
    await file.writeAsString('${DateTime.now().toIso8601String()}: $message\n',
        mode: FileMode.append);
  } catch (e) {
    debugPrint('Error writing message $message to file: $e');
  }
}

/// Entry point for the isolate for our background task
@pragma('vm:entry-point')
void backgroundTask() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await backgroundMain();
      // For the integration test: Send a message to indicate we're finished
      final sendPort = IsolateNameServer.lookupPortByName('test');
      if (sendPort != null) sendPort.send('success');
    } catch (e) {
      await writeLog('Unexpected error while trying to run backgroundMain: $e');
    }
    return Future.value(true);
  });
}

Future<void> backgroundMain() async {
  final prefs = await SharedPreferences.getInstance();

  await writeLog("Background task is starting...");
  final ref = ProviderContainer(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)]);
  await backgroundCheck(ref);

  // TODO: check automatic updates setting; if necessary check connectivity
  // TODO: if all is fine: download languages with updates
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
