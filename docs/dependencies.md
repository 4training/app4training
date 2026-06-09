# Dependencies

Snapshot of the dependency tree as of `pubspec.yaml`. Group-by-purpose, with notes about why each is here and any pinned-version gotchas.

## Runtime dependencies

### Framework
| Package | Why |
| --- | --- |
| `flutter` (sdk) | Of course |
| `flutter_localizations` (sdk) | Provides Material/Cupertino/Widget localization delegates |
| `intl: any` | Date formatting (`DateFormat`) on the settings page; required for generated l10n |

### State management
| Package | Why |
| --- | --- |
| `flutter_riverpod: ^3.3.1` | Riverpod widgets (`ConsumerWidget`, `ProviderScope`, `WidgetRef`) |
| `riverpod: ^3.2.1` | Core Riverpod. **Note**: a few places import `package:riverpod/src/framework.dart` for `$RefArg` to access the family argument inside a `Notifier.build()` — this is a known v3 internal escape hatch |

### Content download / file system
| Package | Why |
| --- | --- |
| `dio: ^5.0.0` | HTTP client used by `LanguageDownloaderImpl` to fetch each language's HTML + PDF zip from GitHub. Mocked in `language_downloader_test.dart` |
| `archive: ^4.0.0` | `ZipDecoder` used by `LanguageDownloaderImpl` to unpack the zip bytes into the staging directory via the injected `FileSystem` |
| `path_provider: ^2.0.11` | `getApplicationDocumentsDirectory()` resolved at startup (`main.dart`) and passed as the `root` for the real `LanguageDownloader`; also used by `background_task.dart` for the debug log file |
| `path: ^1.8.2` | `join()` for cross-platform paths |
| `file: ^7.0.0` | Abstract `FileSystem` API. Backs `fileSystemProvider`, lets tests (including `LanguageDownloader` tests) inject `MemoryFileSystem` |
| `http: ^1.0.0` | The GitHub Commits API call (`Globals.getCommitsSince`). Backs `httpClientProvider` |

### Persistence
| Package | Why |
| --- | --- |
| `shared_preferences: ^2.2.0` | Stores app language, recent page, last-checked timestamps, updatesAvailable booleans, automaticUpdates / checkFrequency settings |

### HTML rendering
| Package | Why |
| --- | --- |
| `flutter_html: ^3.0.0` | Renders worksheet HTML inside the app |
| `flutter_html_table: ^3.0.0` | `<table>` extension. Buggy in 3.0.0 — see error filter in `main.dart` |
| `html: ^0.15.4` | Parser used by `sanitize()` in `widgets/html_view.dart` to pre-process the DOM |

### UI extras
| Package | Why |
| --- | --- |
| `flex_color_scheme: ^8.4.0` | Generates the red Material 3 themes |
| `url_launcher: ^6.3.2` | "Open in browser" + clickable links on About page |
| `flutter_linkify: ^6.0.0` | Auto-link URLs in the localized strings on the About page |
| `share_plus: ^13.0.0` | Native share dialog (PDF and link sharing) |
| `open_filex: ^4.4.0` | Open a downloaded PDF with the user's PDF app |
| `package_info_plus: ^10.0.0` | App version shown on the About page |

### Background work
| Package | Why |
| --- | --- |
| `workmanager: ^0.9.0+3` | Periodic background isolate that calls `backgroundTask()` |

### Test-time helpers shipped as runtime deps
These are listed under `dependencies:` rather than `dev_dependencies:` because some test fixtures live in `lib/background/background_test.dart` (which the integration test imports through the production code path). Keep them where they are.

| Package | Why |
| --- | --- |
| `test: ^1.29.0` | **Pinned**: 1.30+ needs `test_api > 0.7.9` but `flutter_test` pins `test_api 0.7.9` |
| `mocktail: ^1.0.3` | Used for `Dio` mocks in `language_downloader_test.dart` and ad-hoc mocks elsewhere |

## Dev dependencies

| Package | Why |
| --- | --- |
| `flutter_test` (sdk) | Widget testing |
| `flutter_lints: ^6.0.0` | Standard recommended lints, included from `analysis_options.yaml` |
| `full_coverage: ^1.0.0` | CI step generates `test/full_coverage_test.dart` to ensure all files are imported in coverage |
| `riverpod_lint: ^3.1.3` | Riverpod-specific lints. **Note** in `pubspec.yaml`: 3.1.1+ uses `analysis_server_plugin`, replacing the previous `custom_lint`-based plugin. No `analyzer plugins:` entry is required |
| `integration_test` (sdk) | Backs `integration_test/background_interaction_test.dart` |

## Tooling configuration

- **Flutter version**: pinned to `3.41.6` in `.fvmrc`. Use FVM if you have it; otherwise any compatible Flutter SDK works.
- **Dart SDK**: `^3.7.0` (from `pubspec.yaml`).
- **Localization generation**: `generate: true` in `pubspec.yaml` plus `l10n.yaml` triggers `flutter gen-l10n` automatically when running `flutter pub get`.
- **Lints**: `analysis_options.yaml` includes `package:flutter_lints/flutter.yaml` plus a few extras: `unawaited_futures`, `avoid_void_async`, `always_declare_return_types`, `join_return_with_assignment`, `unnecessary_parenthesis`, `no_literal_bool_comparisons`.

## Removed: `custom_lint`

A note in `pubspec.yaml` records that `custom_lint` was removed because `custom_lint 0.8.1` requires `analyzer ^8` while `riverpod_lint >=3.1.1` requires `analyzer ^9`. Since `riverpod_lint 3.1.3` migrated to `analysis_server_plugin`, the separate `custom_lint` runner is no longer needed. **Don't add it back unless you understand why.**
