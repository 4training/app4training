# Architecture

This document explains how `app4training` is wired end-to-end:

- process model,
- layers,
- data flow,
- and where to look for each concern.

## Process and platform model

`app4training` is a single-process Flutter app with **one auxiliary background isolate** (Android `workmanager`).
There is no app-owned backend; all content comes from public GitHub repos and the GitHub REST API.

- **Main isolate**:
  - UI,
  - State (Riverpod `ProviderScope`),
  - Reads/writes to local file system and `SharedPreferences`.
- **Background isolate**:
  - Spawned by `workmanager`. Runs `backgroundTask()` in `lib/background/background_task.dart`,
    builds its own `ProviderContainer`, checks each downloaded language for new GitHub commits,
    persists results to `SharedPreferences`.
    The main isolate later detects the activity by reloading shared prefs (see `BackgroundResultNotifier.checkForActivity`).

> **Note:** Currently the periodic registration of the background task is **commented out** (gated behind "version 0.9").
> The task is wired up and tested in the integration test, but is not actually being scheduled at app launch.

## Layered overview

```
┌──────────────────────────────────────────────────────────────┐
│  Presentation                                                │
│  lib/routes/   → screens (StartupPage, HomePage, ViewPage…)  │
│  lib/widgets/  → MainDrawer, HtmlView, dropdowns, buttons    │
│  lib/features/share/ → Share menu + ShareService             │
│  lib/design/   → ThemeData (FlexColorScheme red)             │
└────────────────────────┬─────────────────────────────────────┘
                         │  reads via Riverpod (WidgetRef)
                         ▼
┌──────────────────────────────────────────────────────────────┐
│  State (Riverpod v3, no codegen)                             │
│  lib/data/globals.dart      → app-wide providers + constants │
│  lib/data/app_language.dart → AppLanguage notifier           │
│  lib/data/languages.dart    → languageProvider (family)      │
│  lib/data/updates.dart      → languageStatusProvider (family)│
│  lib/background/background_scheduler.dart                    │
│  lib/background/background_result.dart                       │
└────────────────────────┬─────────────────────────────────────┘
                         │
        ┌────────────────┼─────────────────────┐
        ▼                ▼                     ▼
┌───────────────┐  ┌──────────────┐  ┌──────────────────────┐
│ File system   │  │ SharedPrefs  │  │ Network              │
│ (download_    │  │ user prefs + │  │ - download_assets    │
│  assets)      │  │ last-checked │  │   (zip download)     │
│ HTML + PDF    │  │ timestamps   │  │ - http (GitHub API)  │
│ per language  │  │              │  │   commits since…     │
└───────────────┘  └──────────────┘  └──────────────────────┘
```

The split is deliberately thin — there is no service/repository layer between providers and IO.
The Riverpod `Notifier` *is* the repository.
This keeps the codebase small at the cost of putting IO directly inside providers,
which is mitigated by overriding `fileSystemProvider` and `httpClientProvider` in tests.

## Lifecycle

1. **`main()`** (`lib/main.dart`)

   - `WidgetsFlutterBinding.ensureInitialized()`
   - `_installHtmlTableSemanticsFilter()` — wraps `FlutterError.onError` to filter four known non-fatal assertions from `flutter_html_table` (see [content-rendering.md](content-rendering.md)).
   - Loads `SharedPreferences` and `PackageInfo` synchronously.
   - `runApp(ProviderScope(overrides: [...], child: App4Training()))`.

1. **`App4Training`** widget

   - Watches `appLanguageProvider` for the current locale.
   - Builds `MaterialApp` with `initialRoute: '/'`, `onGenerateRoute: generateRoutes`,
     light/dark themes from `lib/design/theme.dart`, and a `scaffoldMessengerKey`
     that lets us show snackbars from anywhere via `scaffoldMessengerProvider`.

1. **`StartupPage`** (`/`)

   - Decides where to navigate based on persisted state in `SharedPreferences`. See [onboarding-flow.md](onboarding-flow.md).

1. **`/view/<page>/<lang>`**

   - The "main" view. Loads HTML from disk via `pageContentProvider`, also opportunistically calls `BackgroundResultNotifier.checkForActivity()` to detect work done in the background isolate, persists `recentPage`/`recentLang` so the next launch can resume.

## Data flow: viewing a worksheet

```
ViewPage(page, langCode)
  → checkAndLoad()
       ├─ ref.read(backgroundResultProvider.notifier).checkForActivity()
       │      • reload SharedPreferences
       │      • compare lastChecked-<lang> on disk vs in-memory LanguageStatus
       │      • invalidate stale languageStatusProviders
       │      • show snackbar if activity found
       └─ ref.watch(pageContentProvider((name, langCode))).future
              • watches Language(langCode) for the on-disk path
              • reads <path>/<page.fileName> from FileSystem
              • inlines images by replacing <img src="files/x.png">
                with <img src="data:image/png;base64,…">
              • throws LanguageNotDownloadedException / PageNotFoundException /
                LanguageCorruptedException for the matching cases

→ HtmlView(content, direction)
       • sanitize(content, isDarkMode)  ← workarounds for flutter_html bugs
       • Html.fromDom(...) with TagWrapExtension({'table'}) +
         TableHtmlExtension; tables get wrapped in a horizontal scroll view
       • onAnchorTap pushes /view<href> so internal worksheet links navigate
```

## Data flow: downloading a language

```
DownloadLanguageButton(langCode).onPressed
  → LanguageController(langCode).download(force?)
       • _initController() → DownloadAssetsController.init(assetDir: 'assets-<lang>')
       • startDownload([htmlZipUrl])  ← github.com/4training/html-<lang>/archive/main.zip
       • startDownload([pdfZipUrl])   ← github.com/4training/pdf-<lang>/archive/main.zip
       • _load():
           – read structure/contents.json
           – build pages: Map<String,Page>, pageIndex: List<String>,
             images: Map<String,Image>, pdf paths
           – compute disk usage
           – read modified timestamp of contents.json (UTC) → downloadTimestamp
           – emit new Language state
  → snackbar, button stops spinning
```

The two zip downloads are issued sequentially because `download_assets` errors when both URLs share a filename (`main.zip`). See `LanguageController._download`.

## Data flow: checking for updates

```
CheckNowButton or LanguageStatusNotifier.check()
  → GET https://api.github.com/repos/4training/html-<lang>/commits?since=<downloadTimestamp>
     (httpClientProvider)
  → 200: count commits, persist to SharedPrefs:
         lastChecked-<lang>=<now UTC ISO>
         updatesAvailable-<lang>=<bool>
         emit new LanguageStatus(updatesAvailable, downloadTimestamp, now)
  → 403: API rate-limited (60/h unauthenticated) — return apiRateLimitExceeded
```

The background isolate runs the same `LanguageStatusNotifier.check()`, just with a freshly-built `ProviderContainer` overriding `sharedPrefsProvider`. When the main isolate later reloads SharedPreferences, it sees the fresher `lastChecked-*` and emits `BackgroundResult(foundActivity: true)` plus a snackbar.

## Cross-cutting concerns

- **Localization.** `flutter_localizations` + `intl`. `.arb` files in `lib/l10n/locales/` are the source; `flutter gen-l10n` (run automatically by `flutter pub get` because `generate: true` in `pubspec.yaml`) produces `lib/l10n/generated/`. Access via `context.l10n.<key>` (the extension lives in `lib/l10n/l10n.dart`). See [localization.md](localization.md).
- **Snackbars from anywhere.** `scaffoldMessengerKeyProvider` exposes a `GlobalKey<ScaffoldMessengerState>` that `MaterialApp` uses; `scaffoldMessengerProvider` resolves it to the current state, so async callbacks without a `BuildContext` can show snackbars.
- **Errors.** Domain errors are subclasses of `App4TrainingException` (`lib/data/exceptions.dart`) and have `toLocalizedString(BuildContext)`. `ViewPage` unwraps Riverpod v3 `ProviderException` to get the original.
- **Theme.** `lib/design/theme.dart` builds light + dark themes from `FlexScheme.red`, with a custom darker primary red and a centered bold AppBar title.
