# app4training — Onboarding

Welcome to **app4training** — the offline mobile app for [4training.net](https://www.4training.net), built in Dart/Flutter by [holydevelopers.net](https://holydevelopers.net/).

This document is the entry point for new contributors. It gives you a high-level mental model of the app and points to deep-dive docs in `docs/` for each subsystem.

______________________________________________________________________

## 1. What this app does (in 60 seconds)

- **Offline content viewer** for the discipleship/training worksheets hosted at 4training.net.
- Each translation lives in a **separate GitHub repository** (`html-<langCode>` for HTML and `pdf-<langCode>` for PDFs). The user picks which languages to download; the app fetches the repo as a zip, unpacks it locally, and renders pages from disk.
- **No backend of our own.** GitHub serves the content, the GitHub Commits API tells us when a language has updates, and the app renders the HTML using `flutter_html`.
- Users can **read worksheets**, **switch translations** of the current page, **share** a PDF or link, and **manage** the languages stored on their device.

The supported language list, content URLs, and update-check endpoints are all defined in `lib/data/globals.dart` (the `Globals` class).

______________________________________________________________________

## 2. Getting started

### Prerequisites

- **Flutter 3.41.6** (pinned in `.fvmrc`). Either use [FVM](https://fvm.app/) or any compatible Flutter SDK.
- **Dart SDK ^3.7.0** (set by `pubspec.yaml`).
- For Android builds: standard Android SDK + emulator.
- For iOS builds: Xcode + CocoaPods.

### First run

```bash
flutter pub get
flutter run
```

### Pre-commit checks (must pass for CI to be green)

```bash
dart format .
dart analyze
flutter test
```

The CI workflow at `.github/workflows/main.yaml` runs all of these on every push/PR plus an Android emulator integration test.

> **Note:** the README mentions `dart run custom_lint`. As of the current version, `custom_lint` was removed in favor
> of `riverpod_lint 3.1.3+` which now uses `analysis_server_plugin` directly. There is no separate lint step to run.

______________________________________________________________________

## 3. The 30-second mental model

```

┌───────────────────────────────────────────────────────────────────┐
│  main.dart                                                        │
│   → installs flutter_html error filter (see main.dart docstring)  │
│   → loads SharedPreferences + PackageInfo                         │
│   → wraps App4Training in ProviderScope (Riverpod)                │
└──────────────────────────┬────────────────────────────────────────┘
                           │
              ┌────────────▼─────────────┐
              │  MaterialApp             │  named routes via
              │  initialRoute: '/'       │  generateRoutes()
              └────────────┬─────────────┘
                           │
            ┌──────────────▼───────────────────────────┐
            │  '/' StartupPage  → decides where to go  │  
            │   - first time    → /onboarding/1        │
            │   - missing app lang → /onboarding/2     │
            │   - else → /home or /view/<page>/<lang>  │
            └──────────────┬───────────────────────────┘
                           │
                           ▼
        /home (table of contents)  ─►  /view/<Page>/<lang>  (HtmlView)
        /settings  /about  /onboarding/{1,2,3}

```

State is **all Riverpod** (v3, no codegen). The two big Notifiers are `LanguageController` (per-language download/load)
and `LanguageStatusNotifier` (per-language update check). The rest of state is small Notifiers/Providers around them.

______________________________________________________________________

## 4. Repo layout

| Path | Purpose |
| --- | --- |
| `lib/main.dart` | Entry point, app widget, error-filter setup |
| `lib/routes/` | One file per route/page. `routes.dart` is the named-route dispatcher |
| `lib/routes/onboarding/` | Three onboarding screens (`/onboarding/1..3`) |
| `lib/widgets/` | Reusable UI: drawer, html viewer, language buttons, dropdowns |
| `lib/features/share/` | Share menu (PDF/link/open in browser) and `ShareService` wrapper |
| `lib/data/` | Domain layer — Riverpod providers + immutable models (Language, Page, etc.) |
| `lib/background/` | `workmanager` background task + scheduler + result detection |
| `lib/design/theme.dart` | Theming (FlexColorScheme red) + small UI constants |
| `lib/l10n/` | Localization: `.arb` source, generated delegates, helper extension |
| `assets/` | Static images (logo, share icons) |
| `test/` | Widget + unit tests, plus fixture data in `assets-de/`, `assets-en/` |
| `integration_test/` | Real-device test for background isolate behavior |
| `android/`, `ios/` | Standard Flutter platform folders |
| `.github/workflows/main.yaml` | CI: format, analyze, test, integration test |

______________________________________________________________________

## 5. Where to read next

The detailed docs live in `docs/`. Read them in this order if you're new:

1. **[docs/architecture.md](docs/architecture.md)** — high-level architecture, request flow, providers map.
1. **[docs/dependencies.md](docs/dependencies.md)** — every package in `pubspec.yaml` and what it does.
1. **[docs/state-management.md](docs/state-management.md)** — the Riverpod model: every provider, what it depends on, how it's overridden in tests.
1. **[docs/routing.md](docs/routing.md)** — Navigator 1.0 named routes, deep linking, the route table.
1. **[docs/data-layer.md](docs/data-layer.md)** — `Language`/`Page` models, GitHub download flow, file system layout, exceptions.
1. **[docs/content-rendering.md](docs/content-rendering.md)** — HTML rendering, the `sanitize()` workarounds, `flutter_html_table` filter in `main.dart`.
1. **[docs/onboarding-flow.md](docs/onboarding-flow.md)** — the three onboarding pages and their persistence side-effects.
1. **[docs/features.md](docs/features.md)** — pages, widgets, drawer, share menu, language switcher.
1. **[docs/background-tasks.md](docs/background-tasks.md)** — `workmanager` isolate, the result-sync trick, why parts are commented out.
1. **[docs/localization.md](docs/localization.md)** — `.arb` workflow, `context.l10n` extension, in-app language vs. content language.
1. **[docs/testing.md](docs/testing.md)** — unit/widget tests, fixtures, integration test, CI.
1. **[docs/conventions.md](docs/conventions.md)** — coding conventions, lints, do/don't.

______________________________________________________________________

## 6. Things that will surprise you

These are the load-bearing oddities — read these before changing code in their area.

- **Riverpod v3 internal import.** A few places (`languages.dart`, `updates.dart`) import `package:riverpod/src/framework.dart` to access `$RefArg` for `family` providers when overriding in tests. This is intentional, suppressed via `// ignore` comments.
- **`MustOverrideProvider`** in `globals.dart` is a custom helper that throws unless overridden in a `ProviderScope`. It is used for `sharedPrefsProvider`, `packageInfoProvider`, and `languageDownloaderProvider` so that test environments **must** provide explicit fakes.
- **`LanguageDownloader`** (`lib/data/language_downloader.dart`) is the in-house module that downloads + unzips a language's HTML + PDF into a staging directory and swaps it into place atomically. Failed downloads never destroy prior offline content, concurrent `download()` calls are serialized (peak memory bounded by two zips), and a `.staging` leftover from a crashed run is cleaned up on the next attempt. It replaced the third-party `download_assets` package and is wired up in `main.dart` and the background isolate via `languageDownloaderProvider.overrideWithValue(...)`.
- **`flutter_html` error filter.** `main.dart` installs a `FlutterError.onError` shim that swallows four specific assertions thrown by `flutter_html_table` 3.0.0. Read the long docstring there before touching it — the four assertion variants are documented in detail.
- **HTML pre-processing.** `widgets/html_view.dart` calls `sanitize()` to fix bugs in `flutter_html` (e.g. percent table widths, fuzzy translations, stylized subtitles). Some workarounds are also in the HTML generator (`pywikitools`) upstream.
- **Background task is half-disabled.** Big chunks of `BackgroundScheduler.schedule()` and `Workmanager().initialize` in `main.dart` are commented out, gated on a "version 0.9" milestone. Don't delete them — they are the working scaffolding for the next release.
- **No package on pub.dev.** `pubspec.yaml` has `publish_to: 'none'`.
- **License is AGPL** with an Apple App Store exception. See `LICENSE` and `COPYING.iOS`.
- **`test` is pinned to ^1.29.0** because 1.30+ needs a newer `test_api` than `flutter_test` allows.

______________________________________________________________________

## 7. Common workflows

### Add a new language

1. Add the two-letter code to `availableLanguagesProvider` in `lib/data/globals.dart`.
1. Bump `countAvailableLanguages` in the same file.
1. Add a `language_<code>` entry to both `lib/l10n/locales/app_en.arb` and `app_de.arb`.
1. Add the code to the map in `lib/l10n/l10n.dart` (`getLanguageName`).
1. Confirm `https://github.com/4training/html-<code>` and `pdf-<code>` repos exist and follow the standard structure.
1. If the language is RTL, add it to `Globals.rtlLanguages` in `globals.dart`.

### Add a new worksheet category or worksheet

- Worksheet categories: edit `Category` enum and the `worksheetCategories` map in `lib/data/categories.dart`. Add localized strings for the category name to both `.arb` files.
- The actual worksheets come from each language repo's `structure/contents.json` — they aren't listed in app code.

### Add a new route

- Add a builder branch in `generateRoutes()` (`lib/routes/routes.dart`).
- Place the page widget in `lib/routes/`.
- Update `docs/routing.md`.

### Run a single test

```bash
flutter test test/view_page_test.dart
```

______________________________________________________________________

## 8. Roadmap context (from README)

- **0.9**: enable automatic background updates (scaffolding present but commented out).
- **1.0**: solid release.
- iOS planned for 2024.

If you see code with `TODO for version 0.9`, that's why.
