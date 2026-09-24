# Background Tasks

The app has a `workmanager`-based periodic background task that **checks** for
content updates while the app is closed and, when the user's settings allow it,
**downloads** the languages that have updates. The task is scheduled at the
`CheckFrequency` interval (and not scheduled at all when the user picks
`never`); what it does once it runs is driven by the `AutomaticUpdates` setting.

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
3. Builds a new `ProviderContainer` with `sharedPrefsProvider`, `languageDownloaderProvider` **and** `connectivityServiceProvider` overridden — the background isolate has the same atomicity and concurrency guarantees as the foreground path, plus a way to check the connection type without a `BuildContext`.
4. Runs the two-phase flow: **`backgroundCheck(ref)`** (phase 1) then **`backgroundDownload(ref)`** (phase 2).

### `backgroundCheck(ProviderContainer ref)` — phase 1
For each language code in `availableLanguagesProvider`:
1. `languageProvider(code).notifier.lazyInit()` — minimal disk check, no JSON parse.
2. Skip if not downloaded.
3. `languageStatusProvider(code).check()` — same GitHub Commits API call as the foreground. This refreshes `updatesAvailable-<lang>` / `lastChecked-<lang>` in prefs.
4. Bail out of the loop if the rate limit (`apiRateLimitExceeded`) is hit.

### `backgroundDownload(ProviderContainer ref)` — phase 2
Reads `automaticUpdatesProvider` (from the isolate's own prefs) and decides
whether to download the languages that phase 1 flagged with `updatesAvailable`:

| `AutomaticUpdates`    | metered (mobile) | unmetered (WiFi/ethernet) |
| --------------------- | ---------------- | ------------------------- |
| `never`               | no download      | no download               |
| `requireConfirmation` | no download¹     | no download¹              |
| `onlyOnWifi`          | no download      | download                  |
| `yesAlways`           | download         | download                  |

¹ `requireConfirmation` deliberately leaves `updatesAvailable` set so the
foreground can surface it — see [Confirming updates in the foreground](#confirming-updates-in-the-foreground).

For `onlyOnWifi`, connectivity is queried via `connectivityServiceProvider`
(`ConnectivityService.isUnmetered()`). "Unmetered" means WiFi **or** ethernet —
the user's real intent behind `onlyOnWifi` is "don't burn mobile data". When
downloading, each language with `updatesAvailable` is re-downloaded via
`languageDownloader.download(code)` in a per-language `try`/`catch`, so one
language's failure never aborts the whole run. After each download the language's
`languageStatusProvider` is invalidated so `updatesAvailable` resets to false.

### Connectivity (`lib/data/connectivity_service.dart`)
`ConnectivityService.isUnmetered()` wraps the `connectivity_plus` package
(Android needs the `ACCESS_NETWORK_STATE` permission). It is exposed as
`connectivityServiceProvider`, a `MustOverrideProvider` — the real
`ConnectivityServiceImpl` is wired up in `main.dart` and in `backgroundMain()`,
and tests inject `FakeConnectivityService` (a controllable `unmetered` flag,
living in `lib/background/background_test.dart` next to `FakeLanguageDownloader`).

### Debug logging
`writeLog(message)` appends to `<docDir>/background.log` so the integration test (and human debuggers) can confirm the task ran. Marked `TODO: Remove later`.

## Scheduling (`lib/background/background_scheduler.dart`)

`BackgroundScheduler.schedule()` registers (or cancels) the periodic task
according to the `CheckFrequency` setting:

```dart
Future<void> schedule() async {
  // idempotent re-scheduling: always cancel the prior registration first
  await Workmanager().cancelByUniqueName('backgroundTask');
  final interval = ref.read(checkFrequencyProvider).getDuration(); // null == never
  if (interval == null) {
    state = false;          // CheckFrequency.never -> task stays cancelled
    return;
  }
  await Workmanager().registerPeriodicTask('backgroundTask', 'backgroundTask',
      constraints: Constraints(networkType: NetworkType.connected),
      initialDelay: interval ~/ 2);
  state = true;
}
```

- The provider's `bool` state reflects whether the task is currently scheduled.
- `CheckFrequency.never` → nothing registered, `state = false`.
- The `NetworkType.connected` constraint guarantees *some* connection when the
  task fires (which is why `yesAlways` can download without a connectivity check).
- The `task` name `'backgroundTask'` is what reaches `executeTask` and selects
  the `backgroundMain` branch (kept distinct from `'testTask'`).

`schedule()` is called from three places:
- `StartupPage.init()` after a successful startup,
- `SetUpdatePrefsPage` after the user submits onboarding step 3,
- `CheckFrequencyNotifier.setCheckFrequency` whenever the user changes the frequency.

`main()` calls `Workmanager().initialize(backgroundTask)` to register the isolate
entry point; the periodic scheduling itself is owned entirely by
`BackgroundScheduler` (there is no one-off registration on launch).

Unit tests can't touch the `workmanager` platform channel, so `schedule()`'s
branching logic is mirrored by `TestBackgroundScheduler`
(`test/background_scheduler_test.dart`), which is asserted across every
`CheckFrequency` and for cancel-before-register re-scheduling.

## Confirming updates in the foreground

Under `AutomaticUpdates.requireConfirmation` the background task finds updates but
does not download them. `updatesNeedConfirmationProvider`
(`lib/data/updates.dart`) is true exactly when that setting is active **and**
updates are available. It drives a **persistent indicator**:
- a red dot next to the Settings entry in the drawer (`MainDrawer`), and
- a `ConfirmUpdatesPrompt` on the settings page with a "download now" button that
  runs the normal foreground download path for every language with updates.

After a successful foreground download, `updatesAvailable` resets via the usual
`LanguageStatusNotifier` rebuild, so the indicator and prompt disappear.

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
   - `Workmanager().initialize(backgroundTask)`.
   - `registerOneOffTask(..., 'testTask', initialDelay: 2s)` — `task` argument is what gets passed to `executeTask` and what selects the `backgroundTestMain()` branch.
   - Main isolate registers a port via `IsolateNameServer.registerPortWithName(port.sendPort, 'test')`.
   - `backgroundTask` sends `'success'` via `IsolateNameServer.lookupPortByName('test')`.
   - Main isolate awaits the port message with a 10-second timeout.

2. **"Test synchronization with main isolate"** — full happy-path: mount `App4Training` with `appLanguage='de'`, open settings to warm `languageStatusProvider`, fire the background task, then open a worksheet and verify the `foundBgActivity` snackbar appears.

`backgroundTestMain()` mirrors `backgroundMain()`'s two-phase flow
(`backgroundCheck` then `backgroundDownload`) with a `FakeConnectivityService`,
so the integration test exercises the full check-then-download path
deterministically. The fixtures use `MemoryFileSystem`,
`FakeLanguageDownloader` and `FakeConnectivityService` from
`lib/background/background_test.dart`.

## Why the test fixtures live in `lib/`

`background_test.dart` lives in `lib/background/` rather than `test/` because the integration test imports it through the production `background_task.dart` path (`backgroundTestMain` calls `createTestFileSystem()` and constructs a `FakeLanguageDownloader` from inside the isolate). Test code under `test/` can't be imported by code under `lib/`, so the helpers have to be co-located with production. There's a comment to that effect at the top of the file.
