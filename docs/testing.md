# Testing

## Test layout

```
test/
├── assets-en/html-en-main/                      ← real HTML fixtures used by widget tests
├── assets-de/{html-de-main, pdf-de-main}/       ← bigger German fixture set
├── about_page_test.dart
├── app_language_test.dart
├── background_result_test.dart
├── background_scheduler_test.dart
├── background_task_test.dart
├── check_now_button_test.dart
├── delete_language_button_test.dart
├── download_language_button_test.dart
├── download_languages_page_test.dart
├── dropdownbutton_app_language_test.dart
├── dropdownbutton_automatic_updates_test.dart
├── dropdownbutton_check_frequency_test.dart
├── exceptions_test.dart
├── globals_test.dart
├── html_view_table_test.dart
├── html_view_test.dart
├── language_selection_button_test.dart
├── languages_table_test.dart
├── languages_test.dart                          ← shared helpers (TestLanguageController, FakeDownloadAssetsController, ...)
├── main_drawer_test.dart
├── routes_test.dart
├── set_update_prefs_page_test.dart
├── settings_page_test.dart
├── share_button_test.dart
├── startup_page_test.dart
├── update_language_button_test.dart
├── updates_test.dart                            ← shared helpers (TestLanguageStatus, mockCheckResponse)
├── view_page_test.dart
└── welcome_page_test.dart

integration_test/
└── background_interaction_test.dart             ← real Android emulator
```

## Running

```bash
# All unit + widget tests, with coverage
flutter test --coverage

# A single file
flutter test test/view_page_test.dart

# Integration test (needs Android emulator or device)
flutter test integration_test
```

CI runs both via `.github/workflows/main.yaml`. Coverage uploads to Codecov; the badge in `README.md` reflects this.

## Coverage trick: `full_coverage`

`flutter test --coverage` only counts files that are imported by some test. To make every file in `lib/` count, the CI step:

```yaml
dart pub global activate full_coverage
dart pub global run full_coverage
```

generates `test/full_coverage_test.dart` that imports every file under `lib/`. The local equivalent is the same two commands.

## Shared test helpers

### `test/languages_test.dart`
- **`MockDownloadAssetsController`** (mocktail) — straight `Mock` impl.
- **`FakeDownloadAssetsController`** — minimal hand-written fake exposing `initCalled`, `clearAssetsCalled`, `startDownloadCalls` so tests can assert on call counts.
- **`ThrowingDownloadAssetsController`** — fake that throws from `startDownload` to simulate network failures.
- **`TestLanguageController`** — overrides `LanguageController` to short-circuit `init`/`download` to a configured boolean. Used pervasively by widget tests that don't care about disk state.
- **Helper functions** to build `MemoryFileSystem` instances pre-populated with the German/English fixtures from `test/assets-de/`, `test/assets-en/`.

### `test/updates_test.dart`
- **`TestLanguageStatus`** — overrides `LanguageStatusNotifier` for tests that don't want to mock HTTP.
- **`mockCheckResponse({'de': 2, 'en': 0, ...})`** — builds an `http.Client` (via `mocktail`) that returns the right number of fake commits per language code.

## Standard test scaffolding

Most tests follow this template:

```dart
testWidgets('...', (tester) async {
  SharedPreferences.setMockInitialValues({...});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      packageInfoProvider.overrideWithValue(...),
      languageProvider.overrideWith(() => TestLanguageController(initReturns: true)),
    ],
    child: const MaterialApp(
      locale: Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: SomePage(),
    ),
  ));
  await tester.pumpAndSettle();

  expect(find.text('...'), findsOneWidget);
});
```

Almost every test:
- Sets `SharedPreferences.setMockInitialValues` — the `shared_preferences` plugin's official test API.
- Hardcodes `locale: Locale('de')` (the German strings are the assertion targets in many tests, e.g. "Einstellungen", "Schritte der Vergebung").
- Overrides `sharedPrefsProvider`, `packageInfoProvider`, and the relevant family providers.

## `routes_test.dart` — routing

Uses a `TestObserver extends NavigatorObserver` to record `didPush` and `didReplace` calls. The asserts then check that, given a starting state, the right `pushReplacementNamed` was invoked. This is the cleanest way to verify `StartupPage`'s decision matrix end-to-end.

## Integration test

`integration_test/background_interaction_test.dart` is the only test that runs on a real Android emulator. CI runs it via `reactivecircus/android-emulator-runner@v2` at API level 29 with `arch: x86_64`. Locally:

```bash
flutter test integration_test
```

It:
1. Initializes `Workmanager` with `backgroundTask` as the dispatcher.
2. Registers a one-off task with `task: 'testTask'`, which selects the test branch in `backgroundTask` (calls `backgroundTestMain()` instead of `backgroundMain()`).
3. Uses `IsolateNameServer` to receive a "success" message from the background isolate.
4. The second test additionally verifies that opening a worksheet in the foreground after the background task ran shows the `foundBgActivity` snackbar.

See [background-tasks.md](background-tasks.md) for the full mechanism.

## What's NOT tested

- **Real HTTP** to `api.github.com` or `github.com` — every test uses `httpClientProvider` overrides or `TestLanguageStatus`.
- **Real disk** — `fileSystemProvider` is overridden with `MemoryFileSystem` for download/load tests, or the `test/assets-*` directories are exposed via a `chroot`-style file system.
- **`flutter_html_table` rendering edge cases** — the assertions filtered by `_installHtmlTableSemanticsFilter` in `main.dart` don't reproduce in `flutter_test` (see the docstring there).
- **Real `workmanager`** — only the integration test exercises it.

## Pre-commit checks

Before pushing, run:

```bash
dart format .
dart analyze
flutter test
```
