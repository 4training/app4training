# Localization

The app uses Flutter's [official internationalization workflow](https://docs.flutter.dev/ui/accessibility-and-localization/internationalization) — `.arb` source files compiled into Dart by `flutter gen-l10n`.

## Two distinct "languages" — don't confuse them

| Concept | Stored where | Drives | Values |
| --- | --- | --- | --- |
| **App / UI language** | `appLanguageProvider`, persisted in `SharedPreferences['appLanguage']` | All UI strings (settings, drawer, dialogs, errors) | `system`, `en`, `de` (only — see `AppLanguage.availableAppLanguages`) |
| **Content language** | `languageProvider(<code>)` — per-language download state | Worksheet content shown in `ViewPage` | All 34 codes from `availableLanguagesProvider` |

A user can be reading an Arabic worksheet (content) inside an English UI (app language), or vice versa. The drawer translate-icon flow exists specifically for that case.

## Files

- **Source ARB**: `lib/l10n/locales/app_en.arb`, `lib/l10n/locales/app_de.arb`. ~15-16 KB each.
- **Generated Dart**: `lib/l10n/generated/app_localizations.dart` (the abstract delegate) and `app_localizations_{en,de}.dart` (concrete classes).
- **Config**: `l10n.yaml`:
  ```yaml
  arb-dir: lib/l10n/locales
  template-arb-file: app_en.arb
  output-localization-file: app_localizations.dart
  output-dir: lib/l10n/generated
  nullable-getter: false
  ```
  `nullable-getter: false` means `AppLocalizations.of(context)` returns `AppLocalizations` (not `AppLocalizations?`), simplifying call sites.
- **Auto-regeneration**: `pubspec.yaml` has `flutter: generate: true`, so `flutter pub get` regenerates the delegates whenever `.arb` files change.

## Access pattern: `context.l10n`

The extension in `lib/l10n/l10n.dart` is what you'll see everywhere:

```dart
extension AppLocalizationsExt on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
```

So instead of `AppLocalizations.of(context)!.appLanguage`, the codebase writes `context.l10n.appLanguage`.

Two typical async-callback patterns:
- **Capture before `await`**: `final l10n = context.l10n;` at the top of an async handler, since `BuildContext` is unsafe to use after an async gap.
- **`AppLocalizationsEn` directly**: `Exception.toString()` uses `AppLocalizationsEn()` to produce a stable English message in logs, while `toLocalizedString(context)` uses `context.l10n` for UI display.

## `getLanguageName(<code>)` — dynamic key workaround

Flutter's generated localizations don't currently support dynamic keys ([flutter#105672](https://github.com/flutter/flutter/issues/105672)), so to translate a language code (`'de'`) into its localized name (`'Deutsch (de)'`), `lib/l10n/l10n.dart` defines:

```dart
extension GetLanguageNameExt on AppLocalizations {
  String getLanguageName(String languageCode) {
    final languageMap = <String, String>{
      'tr': language_tr, 'zh': language_zh, ... 'de': language_de
    };
    return languageMap.containsKey(languageCode)
      ? "${languageMap[languageCode]!} ($languageCode)"
      : languageCode.toUpperCase();
  }
}
```

The hardcoded `language_<code>` strings come from the generated `AppLocalizations` (one ARB key per language). **Adding a new content language requires four edits** — see [ONBOARDING.md §7](../ONBOARDING.md#add-a-new-language).

## Wiring in `MaterialApp`

`lib/main.dart`:
```dart
MaterialApp(
  locale: appLanguage.locale,                     // from appLanguageProvider
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  ...
)
```

`AppLanguage.locale` returns `Locale(languageCode)`. When `appLanguage.toString()` is `'system'` we resolve `languageCode` from `LocaleWrapper.languageCode` (which strips the country part of `Platform.localeName`). If that resolves to anything outside `availableAppLanguages`, we fall back to `'en'`.

## Plurals and parameters

The ARB files use ICU MessageFormat for parameterized strings. Examples observed in the codebase:
- `nUpdatesAvailable(count)` — used by `CheckNowButton`.
- `cantDisplayPage(page, languageName)` — used by `ViewPage`.
- `internalError(message)` — used by `ErrorPage`.
- `countLanguages(count)` — used by `LanguagesTable`.
- `updatedNLanguages(count, errors)` — used by `UpdateAllLanguagesButton`.

When you add a parameterized string, define it once in `app_en.arb` (with `@key` metadata for the placeholders) and translate it in `app_de.arb`. `flutter pub get` regenerates the strongly-typed method.

## Testing

Tests typically pass `localizationsDelegates: AppLocalizations.localizationsDelegates` and a fixed `locale: const Locale('de')` (or `'en'`) to `MaterialApp`. Several tests assert against the German strings directly (e.g. `expect(find.text('Schritte der Vergebung'), …)`), so don't change `app_de.arb` casually.
