# Conventions

The unwritten-but-consistent patterns you'll see across the codebase. Follow these unless you have a good reason not to.

## Style and lints

- **`dart format .`** — required before commit. CI doesn't yet `--set-exit-if-changed` (there's a TODO about a strange formatting issue), but `dart format` should produce no diff in normal cases.
- **`dart analyze`** — must be clean.
- **`flutter_lints` + extras** — `analysis_options.yaml` enables: `unawaited_futures`, `avoid_void_async`, `always_declare_return_types`, `join_return_with_assignment`, `unnecessary_parenthesis`, `no_literal_bool_comparisons`. A few candidates are commented out and could be enabled later (`prefer_final_in_for_each`, `directives_ordering`, `dead_code`, `use_string_buffers`).
- **Indentation**: 2 spaces. Lines wrap around 80 cols where reasonable. Trailing commas everywhere multi-arg constructors are involved (so `dart format` produces a vertical layout).

## State

- Anything mutable is a `Notifier<T>` exposed via `NotifierProvider`. **Don't** introduce `ChangeNotifier`, `setState` for cross-widget state, or `package:provider`.
- Prefer `ref.watch(...)` in `build`; use `ref.read(...)` only inside callbacks or when you specifically don't want to rebuild.
- `Notifier<T>` classes go in `lib/data/` (or the relevant feature folder).
- For new global singletons that must be set in `main()`, follow the `MustOverrideProvider<T>()` pattern in `globals.dart` so tests can't accidentally use a real value.
- If you need an async source of truth, prefer `FutureProvider.family` over manually implementing a `FutureBuilder` in widget code. Set `retry: null` if the throw is intentional and shouldn't be auto-retried by Riverpod v3.

## Async + UI

- **Capture `context.l10n`** at the top of any async handler before the first `await` — see the many `final l10n = context.l10n;` lines. `BuildContext` is unsafe across async gaps; `AppLocalizations` is fine to keep.
- **Snackbars from anywhere**: `ref.watch(scaffoldMessengerProvider).showSnackBar(...)`. Don't reach for `ScaffoldMessenger.of(context)` from an async callback.
- **Loading indicators on buttons** that perform a download follow the `_isLoading` `ConsumerStatefulWidget` pattern (see `DownloadLanguageButton`, `UpdateLanguageButton`, `CheckNowButton`). Consider using one of those as a template before inventing a new pattern.

## Routing

- Always use `Navigator.pushNamed` (or `pushReplacementNamed`/`popAndPushNamed` as appropriate) — no anonymous `MaterialPageRoute` builders sprinkled around the codebase. New routes go through `generateRoutes()` in `lib/routes/routes.dart`.

## Files and folders

- **Pages → `lib/routes/`** (or `lib/routes/<flow>/` if grouped, like `onboarding/`).
- **Reusable widgets → `lib/widgets/`** as flat `.dart` files.
- **Feature-specific code with multiple files → `lib/features/<feature>/`** (currently only `share/`).
- **Domain models, providers, exceptions → `lib/data/`**.

## Localization

- Every user-facing string goes through `context.l10n.<key>` — never hardcode strings, even in error messages.
- Any new ARB key requires a translation in **both** `app_en.arb` and `app_de.arb`. CI doesn't enforce this, but tests that assert on German strings will catch missing keys.
- `Exception.toString()` should produce a stable English message (use `AppLocalizationsEn()` directly), not a localized one — exceptions get logged.

## Errors

- Domain errors extend `App4TrainingException` and implement `Exception`. Override both `toString()` (English) and `toLocalizedString(BuildContext)` (localized).
- UI catches Riverpod v3 `ProviderException` and unwraps `.exception` to inspect the underlying error (see `ViewPage`).

## Theme and constants

- App-wide constants live in `Globals` (`lib/data/globals.dart`) or `lib/design/theme.dart`. Don't duplicate `appTitle`, snackbar durations, or smiley sizes locally.
- Don't introduce custom `Color` literals — use `Theme.of(context).colorScheme.*`. Manually-greyed widgets follow the `onSurface.withOpacity(0.12 / 0.38)` pattern from `DownloadLanguagesPage`.

## Comments

The repo's existing code is sparing with comments — but where comments exist, they're substantive (e.g. `_installHtmlTableSemanticsFilter` and `sanitize()` have multi-paragraph docstrings explaining the "why"). Match that bar:

- Don't write comments that restate the code.
- **Do** write comments when the *why* is non-obvious — e.g. why two `download_assets` calls instead of one, why an internal Riverpod import is needed, why a button is intentionally clickable while looking disabled.
- `// FIXME` is used to mark workarounds that should ideally move upstream (`pywikitools`, `flutter_html`).
- `// TODO for version 0.9` marks the v0.9 milestone code.

## Don'ts

- **Don't** add a service/repository layer. Riverpod notifiers ARE the repository.
- **Don't** reintroduce `custom_lint` (removed for analyzer-version conflict).
- **Don't** unpin `download_assets` or `test` without first reading the comments in `pubspec.yaml`.
- **Don't** delete commented-out v0.9 code without project agreement — it's the working scaffold for the next release.
- **Don't** introduce a navigation library (`go_router`, etc.) — Navigator 1.0 is intentional and it interplays cleanly with the URL-mirroring `/view/<page>/<lang>` scheme.
- **Don't** delete the `flutter_html_table` error filter — the four assertion variants are real and well-documented.
