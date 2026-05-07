# State Management

The app uses **Riverpod 2/3** style (with `flutter_riverpod 3.x`), no codegen. Every piece of cross-widget state is a provider; there is no `BLoC`, `Provider`, or `ChangeNotifier`-only code.

This page is the index of every provider in the app — what it holds, what it depends on, and how it is overridden in tests.

## Conventions in this codebase

- **Notifiers, not classes-with-callbacks.** Anything mutable is a `Notifier<T>` exposed via `NotifierProvider`. Anything pure-derived is a `Provider<T>`.
- **Family providers for per-language state.** `languageProvider` and `languageStatusProvider` are `NotifierProvider.family<…, …, String>`, keyed by language code.
- **`MustOverrideProvider<T>()`** (declared in `lib/data/globals.dart`) is a custom helper that creates a `Provider<T>` whose default factory throws `ProviderNotOverriddenException`. Used for `sharedPrefsProvider` and `packageInfoProvider` so that *every* `ProviderScope` in the app or tests must explicitly override them.
- **`retry: null`** is set on a few async providers (`pageContentProvider`, `scaffoldMessengerProvider`) and on `MustOverrideProvider` to disable Riverpod v3's automatic retry, which is undesirable when the failure is intentional.
- **`ref.$arg`** (`package:riverpod/src/framework.dart`) is used inside `LanguageController.build()` and `LanguageStatusNotifier.build()` to read the family argument. This is required when overriding the family with `overrideWith()` in tests, where the argument doesn't pass through the constructor. The import is annotated `// ignore: implementation_imports, invalid_use_of_internal_member`.

## Provider catalog

### App infrastructure (`lib/data/globals.dart`)

| Provider | Type | Purpose |
| --- | --- | --- |
| `sharedPrefsProvider` | `Provider<SharedPreferences>` (must-override) | The single `SharedPreferences` instance, set in `main()` |
| `packageInfoProvider` | `Provider<PackageInfo>` (must-override) | App version etc. for the About page |
| `scaffoldMessengerKeyProvider` | `Provider<GlobalKey<ScaffoldMessengerState>>` | The key passed to `MaterialApp.scaffoldMessengerKey` |
| `scaffoldMessengerProvider` | `Provider<ScaffoldMessengerState>` | Resolves the key to the current state. Used as `ref.watch(scaffoldMessengerProvider).showSnackBar(...)` from any callback |
| `availableLanguagesProvider` | `Provider<List<String>>` | The hardcoded list of 34 supported language codes |
| `automaticUpdatesProvider` | `NotifierProvider<AutomaticUpdatesNotifier, AutomaticUpdates>` | Persisted user preference: never / requireConfirmation / onlyOnWifi (default) / yesAlways |

`AutomaticUpdatesNotifier`:
- `build()` reads `automaticUpdates` from `SharedPreferences`.
- `setAutomaticUpdates(String?)` updates state + persists.
- `persistNow()` is called from the third onboarding screen so that completing onboarding writes the default value to disk explicitly.

`Globals` (a static-only class in the same file) holds the constant URLs (`https://github.com/4training/html-<lang>/archive/refs/heads/main.zip`) and folder names (`html-<lang>-main`).

### App language (`lib/data/app_language.dart`)

| Provider | Type | Purpose |
| --- | --- | --- |
| `appLanguageProvider` | `NotifierProvider<AppLanguageController, AppLanguage>` | The currently selected app/UI language. `AppLanguage` is `(isSystemDefault, languageCode)` |

- `AppLanguage.fromString(str, defaultLangCode)` parses the persisted string. `'system'` resolves to `defaultLangCode` (read from `Platform.localeName` via `LocaleWrapper`). Falls back to `'en'`.
- Currently the app supports only `system | en | de` as the **app** language (`AppLanguage.availableAppLanguages`), even though there are 34 **content** languages.
- `LocaleWrapper.languageCode` is a wrapper around `Platform.localeName` for testability.

### Per-language data (`lib/data/languages.dart`)

| Provider | Type | Purpose |
| --- | --- | --- |
| `fileSystemProvider` | `Provider<FileSystem>` | `LocalFileSystem()` by default; overridden with `MemoryFileSystem` in tests |
| `imageContentProvider` | `Provider.family<String, Resource>` | Returns base64-encoded PNG bytes for a given image. Used by `pageContentProvider` |
| `pageContentProvider` | `FutureProvider.family<String, Resource>` | The HTML body of a worksheet, with images inlined as base64. Throws `LanguageNotDownloadedException` / `PageNotFoundException` / `LanguageCorruptedException`. `retry: null` |
| `languageProvider` | `NotifierProvider.family<LanguageController, Language, String>` | Per-language state: pages, images, PDFs, disk path, size, download timestamp |
| `countDownloadedLanguagesProvider` | `Provider<int>` | Derived count for the settings page |
| `diskUsageProvider` | `Provider<int>` | Sum of all `Language.sizeInKB` |

`LanguageController` is the heart of the app. Methods:
- `init()`: idempotent load from disk. Call once per language at startup.
- `lazyInit()`: like `init()` but cheap — only sets `downloaded` + `path` + timestamp without parsing JSON. Used in the background isolate.
- `download({force=false})`: clears (if forcing), downloads HTML+PDF zips, parses structure.
- `deleteResources()`: clears assets dir, resets state.
- `_load()`: the parser. Reads `structure/contents.json`, scans `pdf-<lang>-main/` for PDF files, registers images in `files/`. Catches all errors and clears the assets dir on failure.

`Language` (immutable data class):
- `languageCode`, `pages: Map<String,Page>`, `pageIndex: List<String>` (menu order), `images`, `path`, `sizeInKB`, `downloadTimestamp` (always UTC).
- `downloaded` getter is `languageCode != ''`.
- `getPageTitles()` returns the menu in order: English-name → translated-title.

### Update checking (`lib/data/updates.dart`)

| Provider | Type | Purpose |
| --- | --- | --- |
| `httpClientProvider` | `Provider<http.Client>` | Default `http.Client()`; overridden in tests |
| `checkFrequencyProvider` | `NotifierProvider<CheckFrequencyNotifier, CheckFrequency>` | never / daily / weekly (default) / monthly / testinterval (15 min) |
| `languageStatusProvider` | `NotifierProvider.family<LanguageStatusNotifier, LanguageStatus, String>` | Per-language status: `(updatesAvailable, downloadTimestamp, lastCheckedTimestamp)` |
| `updatesAvailableProvider` | `Provider<bool>` | Any-language updates? (drives the "update all" button visibility) |
| `lastCheckedProvider` | `Provider<DateTime>` | The oldest `lastCheckedTimestamp` across all downloaded languages, shown on the settings page |

`LanguageStatusNotifier.build()` watches `languageProvider(<langCode>)`, so it re-runs whenever a language is downloaded or deleted (which is by design — it resets the persisted prefs when the language is gone, or refreshes timestamps when freshly downloaded).

`LanguageStatusNotifier.check()` performs the GitHub commits-since query and returns:
- `0`: no updates,
- `> 0`: number of new commits,
- `apiRateLimitExceeded` (-403): hit the 60-req/h unauthenticated limit,
- `-1`: any other error.

### Background isolate sync (`lib/background/background_result.dart`, `background_scheduler.dart`)

| Provider | Type | Purpose |
| --- | --- | --- |
| `backgroundResultProvider` | `NotifierProvider<BackgroundResultNotifier, BackgroundResult>` | Tracks whether the background task did something we should surface |
| `backgroundSchedulerProvider` | `NotifierProvider<BackgroundScheduler, bool>` | State = "task currently scheduled?" (Currently always `false` — body of `schedule()` is commented out for v0.9) |

`BackgroundResultNotifier.checkForActivity()` is the trick that lets the foreground detect background work without IPC: it calls `prefs.reload()` and compares persisted `lastChecked-<lang>` to the in-memory `LanguageStatus.lastCheckedTimestamp`. If the persisted value is newer, it invalidates the corresponding `languageStatusProvider`.

### Sharing (`lib/features/share/share_service.dart`)

| Provider | Type | Purpose |
| --- | --- | --- |
| `shareProvider` | `Provider<ShareService>` | A thin class that wraps `share_plus`, `url_launcher`, and `open_filex` so they can be mocked in tests |

## Override map for tests

The standard test setup is a `ProviderContainer` (or `ProviderScope`) with overrides:

```dart
ProviderContainer(overrides: [
  sharedPrefsProvider.overrideWithValue(prefs),                      // required
  packageInfoProvider.overrideWithValue(packageInfo),                // required if using App4Training
  fileSystemProvider.overrideWith((ref) => MemoryFileSystem()),      // optional
  httpClientProvider.overrideWith((ref) => mockClient),              // optional
  languageProvider.overrideWith2((languageCode) => TestLanguageController(...)),  // optional
  languageStatusProvider.overrideWith(() => TestLanguageStatus()),   // optional
  backgroundSchedulerProvider.overrideWith(() => TestBackgroundScheduler()), // for /startup tests
])
```

See `test/languages_test.dart` for the concrete `Test*` controller classes. They are reused by every other widget test that needs to fake out a downloaded language.
