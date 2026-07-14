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
    persists results to `SharedPreferences`, and — depending on the `AutomaticUpdates` setting and
    connectivity — downloads the languages that have updates.
    The main isolate later detects the activity by reloading shared prefs (see `BackgroundResultNotifier.checkForActivity`).

> **Note:** The periodic task is scheduled by `BackgroundScheduler.schedule()`
> at the `CheckFrequency` interval (not scheduled when `never`), and its run is
> gated by the `AutomaticUpdates` setting (check-only, or download on WiFi /
> always). See `docs/background-tasks.md`.

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
│ LanguageDown- │  │ user prefs + │  │ - dio (zip download  │
│ loader: stag- │  │ last-checked │  │   via Language-      │
│ ing + atomic  │  │ timestamps   │  │   Downloader)        │
│ swap of HTML  │  │              │  │ - http (GitHub API,  │
│ + PDF per lang│  │              │  │   commits since…)    │
└───────────────┘  └──────────────┘  └──────────────────────┘
```

The split is deliberately thin — there is no service/repository layer between providers and IO.
The Riverpod `Notifier` *is* the repository.
This keeps the codebase small at the cost of putting IO directly inside providers,
which is mitigated by overriding `fileSystemProvider` and `httpClientProvider` in tests.

## Lifecycle

0. **Native splash screen** (no Dart code running yet)

   - Covers Android process start, Flutter engine initialization and the `await`s at the top of `main()` - the single longest blank stretch of a cold start, and the one no Dart change can shorten. It shows the app logo on the same background colour as the first Flutter frame, so the hand-over doesn't flash (`values/colors.xml`: `#FFFFFF` light / `#010101` dark, i.e. the scaffold colours of the two themes in `lib/design/theme.dart`).
   - Android: `drawable/launch_background.xml` is the `windowBackground` of both `LaunchTheme` (the system's starting window) and `NormalTheme` (the activity's own window - `FlutterActivity` switches to it in `onCreate()`, well before the first Flutter frame, so a plain colour there would drop the logo for the longest part of the wait); it centers `drawable-nodpi/splash_logo.png` (one 508 px bitmap, scaled by dp) at `@dimen/splash_logo_size` (127dp). On Android 12+ the system draws its own splash first: `values-v31/styles.xml` gives it the same colour and `drawable-v31/splash_icon.xml`, the logo inset by 28% so it sits inside the system's circular mask at the same 127dp - without that the system would upscale the launcher icon and cut its corners off.
   - iOS: `LaunchScreen.storyboard` centers `LaunchImage` (127pt, 1x/2x/3x) on the `LaunchBackground` colour set (light/dark).
   - All resources are hand-maintained, no splash generator package; the bitmaps derive from the 1024 px icon in `ios/Runner/Assets.xcassets/AppIcon.appiconset` with the white corners made transparent.

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
   - Loads languages in stages so the spinner isn't blocked by all 34 of them: a cheap `lazyInit()` for every language, a full `init()` for the one or two the first screen renders, the rest in the background. See [routing.md](routing.md).

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
              • loads all referenced images in parallel and inlines them:
                <img src="files/x.png"> → <img src="data:image/png;base64,…">
              • throws LanguageNotDownloadedException / PageNotFoundException /
                LanguageCorruptedException for the matching cases

→ HtmlView(content, direction)
       • sanitize(content, isDarkMode)  ← workarounds for flutter_html bugs
         (cached per content + brightness, so a rebuild doesn't redo it)
       • Html.fromDom(...) with TagWrapExtension({'table'}) +
         TableHtmlExtension; tables get wrapped in a horizontal scroll view
       • onAnchorTap pushes /view<href> so internal worksheet links navigate
```

## Data flow: downloading a language

```
DownloadLanguageButton(langCode).onPressed
  → LanguageController(langCode).download()
       • ref.read(languageDownloaderProvider).download(langCode)
           – serialize against any in-flight download (max one at a time)
           – rm -rf assets-<lang>.staging        ← crash recovery
           – Future.wait([
               dio.get(htmlZipUrl, responseType: bytes),
               dio.get(pdfZipUrl,  responseType: bytes),
             ])                                  ← github.com/4training/{html,pdf}-<lang>/archive/main.zip
           – decode each zip in a worker isolate (max 2 at a time process-wide)
             → write each entry into .staging via FileSystem
           – on any failure: rm -rf .staging and rethrow (prior data untouched)
           – rename assets-<lang> → assets-<lang>.old (if it existed)
           – rename .staging      → assets-<lang>        (atomic swap)
           – best-effort rm -rf .old
       • _load():
           – stat structure/contents.json → downloadTimestamp (UTC)
           – read structure/contents.json
           – build pages: Map<String,Page>, pageIndex: List<String>,
             images: Map<String,Image>, pdf paths
           – emit new Language state
             (disk usage is not part of it — see languageSizeProvider)
  → snackbar, button stops spinning
```

The HTML and PDF zips are fetched **concurrently**; the in-house `LanguageDownloader` owns staging directory naming, so there is no longer a same-filename collision to work around. See `lib/data/language_downloader.dart` and `LanguageController._download`.

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
