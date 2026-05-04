# Features, Pages, and Widgets

What's on each screen, what each widget does, and where to find it.

## Screens (`lib/routes/`)

### `StartupPage`
Initial loading screen. Computes `init()` (see [routing.md](routing.md)), shows a `loadingAnimation('Loading')` spinner while the future is pending, navigates with `pushReplacementNamed` once decided. The `initFunction` constructor parameter is exposed only for tests so that `StartupPage` can drive `Navigator` against a `Completer<String>`.

### `HomePage` (`/home`)
Minimal — an `AppBar(title: '4training')`, the `MainDrawer`, and a `TableOfContent` body with the localized "What this app is" intro at the top.

### `ViewPage` (`/view/<page>/<langCode>`)
The main reading screen.
- AppBar actions: `ShareButton` and `LanguageSelectionButton`.
- Drawer: `MainDrawer(page, langCode)` so the current page is highlighted and the right category is auto-expanded.
- Body: `FutureBuilder` over `checkAndLoad()`, which:
  1. Calls `BackgroundResultNotifier.checkForActivity()` first; if true, shows a `foundBgActivity` snackbar.
  2. Awaits `pageContentProvider((name: page, langCode: langCode)).future`.
  3. Renders `HtmlView(content, direction)`, where direction is `RTL` for `Globals.rtlLanguages` (`ar`, `fa`).
- Error handling: if the provider throws, unwraps Riverpod v3 `ProviderException`, then maps `LanguageNotDownloadedException`/`PageNotFoundException` to a warning-style `ErrorMessage`, `LanguageCorruptedException` to a red `ErrorMessage`, and anything else to a generic internal-error message.
- Side-effect: persists `recentPage`/`recentLang` on every successful render.

### `SettingsPage` (`/settings`)
Three sections:
1. **App language** — `DropdownButtonAppLanguage`.
2. **`LanguageSettings`** — title + explanation text + `LanguagesTable` (the per-language download/update/delete table).
3. **`UpdateSettings`** — "Last check" timestamp + `CheckNowButton`. The check-frequency and automatic-updates dropdowns are commented out (for v0.9).

### `AboutPage` (`/about`)
Static text + version. Renders localized strings via `flutter_linkify` so URLs in the strings become tappable (`url_launcher`).

### `ErrorPage`
Internal fallback. Just shows an `ErrorMessage` with the localized "internal error" template; `MainDrawer` is still attached so the user isn't stranded.

## Widgets (`lib/widgets/`)

### `MainDrawer` & `TableOfContent`
The drawer plus a re-usable `TableOfContent` (used directly by `HomePage`). Top-level structure:

```
header (defaults to "Content" tappable, navigates to /home)
└─ for each Category:
     CategoryTile
       └─ for each worksheet in this language belonging to this category:
            • TextButton with translated title (highlighted if it's the current page)
            • optional translate icon (only if user is currently viewing a different language than the app language)
                – if translation exists: opens AvailableInDialog → navigates to /view/<page>/<otherLang>
                – if not: opens NotTranslatedDialog (greyed icon)
─ Divider
─ Settings (Icon, navigates to /settings)
─ About (Icon, navigates to /about)
```

When the *app language* isn't downloaded, the drawer body becomes a single error message using `LanguageNotDownloadedException`'s localized text.

The `Tap on a translated worksheet that doesn't exist in the language you came from` flow shows a snackbar explaining the language fallback (`languageChangedBack`).

### `HtmlView`
See [content-rendering.md](content-rendering.md) for full details. Public surface: `HtmlView(String content, TextDirection direction)`.

### `LanguagesTable`
The settings/onboarding-step-2 table. Each row:
- ✓ if downloaded
- localized language name
- update icon (if updates available, via `UpdateLanguageButton`) or empty
- download icon (`DownloadLanguageButton`, optionally highlighted via `highlightLang`) **or** delete icon (`DeleteLanguageButton`) depending on download state

Header row has the four "all-languages" buttons:
- `IsDownloaded(allDownloaded)`
- `UpdateAllLanguagesButton` (only renders when `updatesAvailableProvider` is true)
- `DownloadAllLanguagesButton`
- `DeleteAllLanguagesButton`

Below the table: `diskUsage` total and a "X of Y languages" counter.

### Language buttons
- **`DownloadLanguageButton`** (`ConsumerStatefulWidget`): icon with internal `_isLoading` flag — swaps to `CircularProgressIndicator` during `LanguageController.download()`. Optional `highlight` flag wraps it in a tinted rounded box (used during onboarding).
- **`DownloadAllLanguagesButton`**: same idea, iterates `availableLanguagesProvider`.
- **`DeleteLanguageButton`**: deleting the *current app language* is "discouraged" — the icon turns `inversePrimary` and clicking shows a `ConfirmDeletionDialog`.
- **`DeleteAllLanguagesButton`**: skips the current app language without prompting.
- **`UpdateLanguageButton`**: same loading pattern, calls `download(force: true)`.
- **`UpdateAllLanguagesButton`**: only visible when `updatesAvailableProvider` is true; iterates languages where `languageStatusProvider(code).updatesAvailable && languageProvider(code).downloaded`.

### `CheckNowButton`
Iterates downloaded languages and calls `LanguageStatusNotifier.check()` for each. Reports via snackbar:
- success: "N updates available" (via `nUpdatesAvailable`)
- rate limit: "checkingUpdatesLimit"
- other error: "checkingUpdatesError"

### Dropdowns
Tiny widgets that map a Riverpod provider to a `DropdownButton`. All three follow the same pattern:
- `DropdownButtonAppLanguage` ↔ `appLanguageProvider`
- `DropdownButtonCheckFrequency` ↔ `checkFrequencyProvider`
- `DropdownButtonAutomaticUpdates` ↔ `automaticUpdatesProvider`

### `LanguageSelectionButton`
The translate icon in the AppBar of `ViewPage`. Lists all downloaded languages that have the current page translated (via `language.pages.containsKey(currentPage)`). If the list is longer than 10, splits into two columns. Bottom of the menu: "Manage languages" → `/settings`. Implemented with `MenuAnchor` + `MenuItemButton` (Material 3 idiom).

### `ShareButton` (`lib/features/share/`)
The share icon in the AppBar of `ViewPage`. Four entries:
- **Open PDF** — `OpenFilex.open(pdfFile)`. Greyed out if `Page.pdfPath` is null. If user clicks the disabled entry, shows `PdfNotAvailableDialog`.
- **Share PDF** — `SharePlus.share(ShareParams(files: [XFile(pdfFile)]))`. Same disabled behavior.
- **Open in browser** — `url_launcher.launchUrl(https://www.4training.net/<page>/<lang>)`.
- **Share link** — `SharePlus.share(ShareParams(text: <url>))`.

The wrapper `ShareService` (and `shareProvider`) exists *purely* for testability; `share_plus`/`open_filex`/`url_launcher` are static APIs that can't easily be mocked otherwise. The note in `share_service.dart` explains that dependency injection isn't easy because of `context.findAncestorWidgetOfExactType`, so wrapping into a service is the cleanest route.

### `ErrorMessage`
A reusable card with an icon, title, and message. Used by `ErrorPage` and by `ViewPage`'s error states.

### `loadingAnimation(msg)`
Function (not a class) returning a `Scaffold` with a centered `CircularProgressIndicator` + label. Used during startup and when fetching page content.

## Sharing assets

Static images live in `assets/`:
- `for_training.png` — the logo (used in `WelcomePage` `PromoBlock`).
- `file-document-outline.png` — Open PDF icon.
- `file-document-arrow-right-outline.png` — Share PDF icon.
- `link.png` — Share link icon.

`pubspec.yaml` only registers `assets/` (without trailing wildcards), which includes everything in that folder. `share_button.dart` has a `// TODO: Use build_runner with flutter_gen instead` for generating typed asset references.
