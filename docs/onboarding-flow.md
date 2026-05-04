# Onboarding Flow

Three sequential screens shown the first time the app runs. Each persists its own subset of `SharedPreferences` keys; `StartupPage` uses the *presence* of those keys to decide which step (if any) to resume.

## Step 1 — `WelcomePage` (`/onboarding/1`)

File: `lib/routes/onboarding/welcome_page.dart`.

- Hero "Welcome" text + the `PromoBlock` (logo, app name, four bullet points).
- A `DropdownButtonAppLanguage` lets the user pick the **app/UI language** (currently only `system`, `en`, or `de`).
- "Continue" button:
  - Calls `appLanguageProvider.notifier.persistNow()` so that the chosen `appLanguage` is now saved (this is the key `StartupPage` uses to decide first-run-vs-not).
  - `Navigator.pushReplacementNamed(context, '/onboarding/2')`.

`PromoBlock` is reused on the About page.

The page is wrapped in `LayoutBuilder + SingleChildScrollView + ConstrainedBox(minHeight: viewport) + IntrinsicHeight + Spacer` so that on tall devices it fills the screen and on small devices it scrolls.

## Step 2 — `DownloadLanguagesPage` (`/onboarding/2`)

File: `lib/routes/onboarding/download_languages_page.dart`.

- Renders the same `LanguagesTable` widget used on the settings page, but with `highlightLang: appLanguage.languageCode` so the user's app-language download button is visually highlighted.
- "Continue" is disabled-looking until the app language is downloaded:
  - Implementation note: we don't set `onPressed: null` (which would also disable click handling). We pass a manually-greyed `ButtonStyle` (`onSurface.withOpacity(0.12)` background, `0.38` foreground) so the button stays clickable. Clicking it while not yet downloaded shows a `MissingAppLanguageDialog` warning.
  - Once the app language is downloaded, "Continue" routes to `getNextRoute(ref)`. Currently that always returns `/home` — for v0.9 this will branch to `/onboarding/3` if `checkFrequency` isn't set yet.
- "Back" returns to `/onboarding/1`.

## Step 3 — `SetUpdatePrefsPage` (`/onboarding/3`)

File: `lib/routes/onboarding/set_update_prefs_page.dart`.

> Currently **bypassed during normal startup** (the corresponding branch in `StartupPage.init()` is commented out, gated for v0.9). The page works end-to-end and is exercised by tests, just not reachable from the regular onboarding chain.

- `DropdownButtonCheckFrequency` (never / daily / weekly / monthly / 15-min test interval).
- `DropdownButtonAutomaticUpdates` (never / requireConfirmation / onlyOnWifi / yesAlways).
- "Let's go" button:
  1. `automaticUpdatesProvider.notifier.persistNow()` — writes the *current* dropdown value (which may be the default if user didn't change it) to `SharedPreferences`. Without this step, `StartupPage` would think onboarding wasn't completed.
  2. `checkFrequencyProvider.notifier.persistNow()` — same.
  3. `backgroundSchedulerProvider.notifier.schedule()` — registers the periodic task (currently a no-op since the body is commented out for v0.9).
  4. `Navigator.pushReplacementNamed(context, '/home')`.

## Persistence map

| Pref key | Set when | Read by |
| --- | --- | --- |
| `appLanguage` | After step 1 (`persistNow`) | `StartupPage` (first-run gate), `AppLanguageController.build` |
| `automaticUpdates` | After step 3 + every dropdown change | `AutomaticUpdatesNotifier.build` |
| `checkFrequency` | After step 3 + every dropdown change | `CheckFrequencyNotifier.build`, **(once enabled)** `StartupPage` (third-step gate) |
| `recentPage`, `recentLang` | After every `ViewPage` render | `StartupPage` for resume |
| `lastChecked-<lang>`, `updatesAvailable-<lang>` | `LanguageStatusNotifier.check()` (foreground or background) | `LanguageStatusNotifier.build`, `BackgroundResultNotifier.checkForActivity` |

## "Continue greyed-out, but clickable" pattern

A recurring trick. `ElevatedButton` has no clean way to look disabled but still respond to taps. The button is therefore styled greyed-out manually (matching `ElevatedButton.defaultStyleOf` opacity values) while keeping `onPressed` non-null and showing a warning dialog inside the handler. This is encapsulated in step 2's `ButtonStyle buttonStyle` ternary.

## Tests

- `test/welcome_page_test.dart`
- `test/download_languages_page_test.dart`
- `test/set_update_prefs_page_test.dart`
- `test/startup_page_test.dart` — the routing-decision tests for the four startup states.

These tests use `TestLanguageController(initReturns: bool, downloadReturns: bool)` from `test/languages_test.dart` to fake out the disk state.
