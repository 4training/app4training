import 'package:app4training/data/globals.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/data/updates.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The results of the background task (if it ran and did something)
/// Currently it holds just a bool but this will be extended
/// to hold detailled information in case there was some activity
@immutable
class BackgroundResult {
  final bool foundActivity;

  const BackgroundResult(this.foundActivity);

  @override
  String toString() {
    return 'Background result: activity = $foundActivity';
  }
}

class BackgroundResultNotifier extends Notifier<BackgroundResult> {
  @override
  BackgroundResult build() {
    return const BackgroundResult(false);
  }

  /// Check whether the background task found updates and if yes: read results
  /// Returns whether we found activity of the background task
  ///
  /// Implementation: Are the lastChecked dates
  /// in the SharedPreferences newer than what we have stored in languageStatus?
  /// (TODO see overview over synchronization with background isolate)
  ///
  /// Remark: languageStatusProviders must have been initialized already before,
  /// otherwise they're loading their lastChecked times from sharedPrefs now
  /// and can't detect any background activity
  Future<bool> checkForActivity() async {
    debugPrint("Checking for background activity");
    bool foundBgActivity = false;

    // Reload SharedPreferences because they're cached
    // May need to change when SharedPreferences gets an API to directly
    // use it asynchronously: https://github.com/flutter/packages/pull/5210
    await ref.read(sharedPrefsProvider).reload();

    for (String languageCode in ref.read(availableLanguagesProvider)) {
      // We don't check languages that are not downloaded
      if (!ref.read(languageProvider(languageCode)).downloaded) continue;

      DateTime lcTimestampOrig =
          ref.read(languageStatusProvider(languageCode)).lastCheckedTimestamp;
      DateTime? lcTimestamp;
      String? lcRaw =
          ref.read(sharedPrefsProvider).getString('lastChecked-$languageCode');
      if (lcRaw != null) {
        try {
          lcTimestamp = DateTime.parse(lcRaw).toUtc();
        } on FormatException {
          debugPrint(
              'Error while trying to parse lastChecked timestamp: $lcRaw');
          lcTimestamp = null;
        }
      }
      if ((lcTimestamp != null) &&
          (lcTimestamp.compareTo(DateTime.now()) <= 0) &&
          lcTimestamp.compareTo(lcTimestampOrig) > 0) {
        // It looks like there has been background activity!
        debugPrint("Background activity detected for language '$languageCode': "
            'lastChecked was $lcTimestampOrig, sharedPrefs says $lcTimestamp');
        foundBgActivity = true;
        // invalidate the languageStatusProvider so it re-reads its value
        // from the shared preferences on next access
        ref.invalidate(languageStatusProvider(languageCode));
      } else {
        debugPrint("No background activity for language '$languageCode'. "
            'lastChecked: $lcTimestampOrig, sharedPrefs says $lcRaw');
      }
    }
    debugPrint('Checking for background activity done');
    state = BackgroundResult(foundBgActivity);
    return foundBgActivity;
  }
}

final backgroundResultProvider =
    NotifierProvider<BackgroundResultNotifier, BackgroundResult>(() {
  return BackgroundResultNotifier();
});
