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
4. Calls **`backgroundRun(ref)`**, which first
   [skips the run if the check frequency isn't due yet](#skipping-runs-before-the-check-frequency-is-due)
   and otherwise runs the two-phase flow: **`backgroundCheck(ref)`** (phase 1) then **`backgroundDownload(ref)`** (phase 2).
   On iOS phase 2 doesn't run here — see
   [iOS: downloads run in a separate processing task](#ios-downloads-run-in-a-separate-processing-task).

### iOS: downloads run in a separate processing task
On iOS the periodic task is a `BGAppRefreshTask`, which gets roughly **30
seconds** — enough to start the headless engine and check every language, but
not to download whole languages. So the work is split into two iOS tasks:

1. **`backgroundTask`** (refresh task, daily): `backgroundMain()` calls
   `backgroundRun(ref, deferDownload: ...)`. After phase 1, instead of
   downloading, it calls `deferDownload` if
   - `AutomaticUpdates` is `onlyOnWifi` or `yesAlways`, **and**
   - at least one language has `updatesAvailable`.

   `deferDownload` submits the processing task with
   `Workmanager().registerProcessingTask('backgroundDownload', ...,
   constraints: Constraints(networkType: NetworkType.connected))`
   (→ `requiresNetworkConnectivity`). Submitting again replaces a pending
   request, so repeated runs don't pile up tasks.
2. **`backgroundDownload`** (`BGProcessingTask`, `processing` background mode):
   iOS runs it when it sees fit — usually while the device is idle, often
   charging and on WiFi — and gives it several minutes. `backgroundTask()`
   routes it to `backgroundDownloadMain()`, which builds a fresh container and
   runs **`backgroundDownload(ref)`** (phase 2). That re-reads
   `AutomaticUpdates` and, for `onlyOnWifi`, the connection type *at that
   moment*.

`onlyOnWifi` on mobile data during the check still schedules the processing
task: it typically runs later, likely on WiFi, and checks the connection
before downloading anything.

Native setup: `ios/Runner/Info.plist` lists `processing` in
`UIBackgroundModes` and `backgroundDownload` in
`BGTaskSchedulerPermittedIdentifiers`; `AppDelegate.swift` calls
`WorkmanagerPlugin.registerBGProcessingTask(withIdentifier:
"backgroundDownload")`. The identifier must match `backgroundDownloadTask` in
`background_task.dart`.

**Android is unchanged**: `backgroundMain()` passes no `deferDownload`, so
WorkManager's task downloads right after checking (it has no comparable time
limit).

#### When iOS cancels a download
If iOS expires the processing task, the process is suspended or killed
mid-download. `LanguageDownloaderImpl.download` never touches the installed
version until the very end: it extracts into `assets-<lang>.staging`, then
swaps with two renames (`assets-<lang>` → `assets-<lang>.old`, staging →
`assets-<lang>`). A kill before the swap only leaves a staging dir, which the
next download removes. A kill **between the two renames** would leave only
`assets-<lang>.old` — the language would look deleted. So
`LanguageDownloader.restoreInterruptedDownload(lang)` renames `.old` back
(or, if the swap already finished, deletes the leftover `.old`, which would
otherwise make the next swap fail). `LanguageController.lazyInit()` and
`init()` call it before looking at the language on disk, so the previous
version is back the first time the app (or the next background run) looks at
the language.

The split is unit-tested in `test/background_ios_download_split_test.dart`
(`backgroundRun` with a counting `deferDownload`); the recovery in
`test/languages_test.dart` and `test/language_downloader_test.dart`.

### Skipping runs before the check frequency is due
`backgroundRun(ref, {now})` exits early — no check, no download, no network
calls — unless the user's `CheckFrequency` interval has (roughly) elapsed:

- `CheckFrequency.never` → always skip (a stray run, e.g. from the native iOS
  registration, must not touch the network).
- Otherwise it compares `now` with **`mostRecentCheck(ref)`**: the *most recent*
  `lastCheckedTimestamp` over all downloaded languages. (Not the oldest like
  `lastCheckedProvider`: `backgroundCheck` doesn't re-check languages that
  already have `updatesAvailable`, so their timestamps stay old and no run
  would ever be skipped.) No downloaded language → the run goes ahead.
- The run is skipped only if **less than 90% of the interval** has elapsed. The
  10% tolerance matters: the OS schedules the next run relative to when the
  previous run *started*, while `lastChecked` is written a few seconds later —
  a strict comparison would skip correctly-scheduled runs.

**Why it exists — iOS runs at a fixed daily frequency.** On iOS the periodic
task is registered natively in `AppDelegate.swift`
(`WorkmanagerPlugin.registerPeriodicTask(withIdentifier: "backgroundTask",
frequency: 24h)`, the shortest `CheckFrequency`). The Dart
`registerPeriodicTask(... initialDelay: interval ~/ 2)` only affects the first
run; after that `workmanager_apple` reschedules the task daily regardless of
the chosen frequency (and iOS may run it later than requested, never earlier).
With `weekly`, the daily wake-ups on days 1–6 therefore exit early and the one
on day ~7 checks. With `daily` nothing changes.

**On Android no run is skipped**: WorkManager already runs the task at the
requested interval, and the 10% tolerance absorbs the scheduling jitter.

`backgroundTestMain()` deliberately doesn't go through `backgroundRun`: its fake
language was just "downloaded", so the run the integration test needs would be
skipped.
The decision is unit-tested per `CheckFrequency` in
`test/background_check_frequency_test.dart`, driving `backgroundRun` with an
injected `now` and a counting `MockClient`.

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

`backgroundTestMain()` mirrors `backgroundMain()`'s two-phase flow (without skipping runs based on `CheckFrequency`)
(`backgroundCheck` then `backgroundDownload`) with a `FakeConnectivityService`,
so the integration test exercises the full check-then-download path
deterministically. The fixtures use `MemoryFileSystem`,
`FakeLanguageDownloader` and `FakeConnectivityService` from
`lib/background/background_test.dart`.

## Why the test fixtures live in `lib/`

`background_test.dart` lives in `lib/background/` rather than `test/` because the integration test imports it through the production `background_task.dart` path (`backgroundTestMain` calls `createTestFileSystem()` and constructs a `FakeLanguageDownloader` from inside the isolate). Test code under `test/` can't be imported by code under `lib/`, so the helpers have to be co-located with production. There's a comment to that effect at the top of the file.
