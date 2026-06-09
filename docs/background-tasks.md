# Background Tasks

The app has a `workmanager`-based periodic background task that **checks** for content updates while the app is closed. Note: as of v0.8 the *scheduling* of this task is **disabled** (commented out, gated for v0.9). The task implementation is complete and integration-tested; only the registration is dormant.

## What runs in the background

### Entry point: `backgroundTask()` (`lib/background/background_task.dart`)
```dart
@pragma('vm:entry-point')
void backgroundTask() {
  Workmanager().executeTask((task, inputData) async {
    if (task == 'testTask') {
      await backgroundTestMain();           // integration test path
      IsolateNameServer.lookupPortByName('test')?.send('success');
    } else {
      await backgroundMain();
    }
    return Future.value(true);
  });
}
```

`@pragma('vm:entry-point')` is required so tree-shaking doesn't remove the function — `workmanager` reaches it through the platform channel by name.

### `backgroundMain()`
1. Gets a fresh `SharedPreferences` instance (the background isolate has its own memory).
2. Resolves `getApplicationDocumentsDirectory()` and builds a real `LanguageDownloaderImpl` with a fresh `Dio` and the local `FileSystem`.
3. Builds a new `ProviderContainer` with `sharedPrefsProvider` **and** `languageDownloaderProvider` overridden — the background isolate has the same atomicity and concurrency guarantees as the foreground path.
4. Calls `backgroundCheck(ref)`.
5. Currently, the task only checks for updates, never auto-downloads.

### `backgroundCheck(ProviderContainer ref)`
For each language code in `availableLanguagesProvider`:
1. `languageProvider(code).notifier.lazyInit()` — minimal disk check, no JSON parse.
2. Skip if not downloaded.
3. `languageStatusProvider(code).check()` — same GitHub Commits API call as the foreground.
4. Bail out of the loop if the rate limit (`apiRateLimitExceeded`) is hit.

### Debug logging
`writeLog(message)` appends to `<docDir>/background.log` so the integration test (and human debuggers) can confirm the task ran. Marked `TODO: Remove later`.

## Scheduling (`lib/background/background_scheduler.dart`)

The current code is essentially:

```dart
class BackgroundScheduler extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> schedule() async {
    /* TODO Enable this with version 0.9
       cancelByUniqueName('backgroundTask')
       interval = checkFrequency.getDuration()  // null if 'never'
       if interval == null: state = false; return
       Workmanager().registerPeriodicTask('backgroundTask', 'backgroundTask',
           constraints: Constraints(networkType: NetworkType.connected),
           initialDelay: interval ~/ 2)
       state = true
    */
  }
}
```

`schedule()` is called from three places (and is currently a no-op):
- `StartupPage.init()` after a successful startup,
- `SetUpdatePrefsPage` after the user submits onboarding step 3,
- `CheckFrequencyNotifier.setCheckFrequency` whenever the user changes the frequency.

The `Workmanager().initialize(backgroundTask, isInDebugMode: false)` call in `main()` is also commented out behind the same `TODO enable in version 0.9`.

## How the foreground learns about background work

There is **no IPC** between isolates. They communicate via `SharedPreferences` (which is backed by a platform plugin storing data on disk).

- The background task writes:
  - `lastChecked-<lang>` (UTC, ISO-8601),
  - `updatesAvailable-<lang>` (bool).

- The foreground later:
  1. `BackgroundResultNotifier.checkForActivity()` is called from `ViewPage.checkAndLoad`.
  2. `await sharedPrefsProvider.read.reload()` — `SharedPreferences` caches values aggressively, so we have to force a re-read from disk.
  3. For each downloaded language, parse `lastChecked-<lang>` from prefs and compare with the in-memory `LanguageStatus.lastCheckedTimestamp`. If the persisted value is newer, **`ref.invalidate(languageStatusProvider(<lang>))`** so it rebuilds from the fresh persisted values.
  4. If any activity was detected, return `true` and the caller shows the `foundBgActivity` snackbar.

There's a comment in `BackgroundResultNotifier.checkForActivity`: "*languageStatusProviders must have been initialized already before, otherwise they're loading their lastChecked times from sharedPrefs now and can't detect any background activity.*" The integration test deliberately opens and closes the settings page first (which mounts `LanguagesTable` and pre-warms `languageStatusProvider` for every language) before triggering the background task.

## Integration test — `integration_test/background_interaction_test.dart`

Two tests, both running on a real Android emulator (CI uses `reactivecircus/android-emulator-runner@v2`, API level 29):

1. **"Test that background task gets executed"**
   - `Workmanager().initialize(backgroundTask, isInDebugMode: false)`.
   - `registerOneOffTask(..., 'testTask', initialDelay: 2s)` — `task` argument is what gets passed to `executeTask` and what selects the `backgroundTestMain()` branch.
   - Main isolate registers a port via `IsolateNameServer.registerPortWithName(port.sendPort, 'test')`.
   - `backgroundTask` sends `'success'` via `IsolateNameServer.lookupPortByName('test')`.
   - Main isolate awaits the port message with a 10-second timeout.

2. **"Test synchronization with main isolate"** — full happy-path: mount `App4Training` with `appLanguage='de'`, open settings to warm `languageStatusProvider`, fire the background task, then open a worksheet and verify the `foundBgActivity` snackbar appears.

The fixtures use `MemoryFileSystem` and `FakeLanguageDownloader` from `lib/background/background_test.dart`.

## Why the test fixtures live in `lib/`

`background_test.dart` lives in `lib/background/` rather than `test/` because the integration test imports it through the production `background_task.dart` path (`backgroundTestMain` calls `createTestFileSystem()` and constructs a `FakeLanguageDownloader` from inside the isolate). Test code under `test/` can't be imported by code under `lib/`, so the helpers have to be co-located with production. There's a comment to that effect at the top of the file.
