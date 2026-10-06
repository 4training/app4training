# Routing

The app uses **Navigator 1.0** with **named routes** — no `go_router`, no nested navigators. The single dispatcher is `generateRoutes(RouteSettings)` in `lib/routes/routes.dart`, plugged into `MaterialApp.onGenerateRoute`.

## Route table

| Route | Page widget | Notes |
| --- | --- | --- |
| `/` (or null) | `StartupPage` | Loading screen + initialization. Decides where to go next |
| `/home` | `HomePage` | Table of contents, in the user's app language |
| `/view/<page>/<langCode>` | `ViewPage(page, langCode)` | The "real" worksheet view. Deep-linkable. Mirrors the URL on 4training.net |
| `/settings` | `SettingsPage` | Manage languages + check-for-updates UI |
| `/about` | `AboutPage` | About text + license + version |
| `/onboarding` or `/onboarding/1` | `WelcomePage` | App language selection |
| `/onboarding/2` | `DownloadLanguagesPage` | Download required language(s) |
| `/onboarding/3` | `SetUpdatePrefsPage` | Update preferences (reached while `checkFrequency` is unset) |
| anything else | `ErrorPage('Unknown route ...')` | Final fallback |

`/view` malformed (missing parts) redirects to `/home`. The dispatcher logs every incoming route via `debugPrint`.

## Why named routes

The README spells this out: pages live at `/view/<page>/<langCode>`, matching exactly the URL of the same worksheet on `4training.net` (e.g. `/view/Dealing_with_Money/de` ↔ `https://www.4training.net/Dealing_with_Money/de`). This makes deep links and link-tap handling inside the HTML body almost trivial — `HtmlView.onAnchorTap` just does `Navigator.pushNamed(context, '/view$url')`.

## Initial navigation logic

`StartupPage.init()` (`lib/routes/startup_page.dart`) is the one place that decides where the user lands on app launch:

```
StartupPage.init():
  if SharedPreferences['appLanguage'] is null:
      return '/onboarding/1'                 # first time

  # step 1: which languages are on the device? one stat() each, in parallel
  stage.report(checkingLanguages)
  await Future.wait(languageProvider(code).notifier.lazyInit() for all codes)

  if app language is not yet downloaded:
      return '/onboarding/2'                 # resume onboarding

  if SharedPreferences['checkFrequency'] is null:
      return '/onboarding/3'                 # third onboarding step

  if SharedPreferences['recentPage'] && 'recentLang' && language is downloaded:
      navigateTo = '/view/<recentPage>/<recentLang>'   # resume last worksheet
  else:
      navigateTo = '/home'

  # step 2: fully load only what the first screen renders
  stage.report(loadingAppLanguage)
  await Future.wait(languageProvider(code).notifier.init()
                    for code in {appLanguage, recentLang?})
      # once the app language is in and recentLang is still loading:
      # stage.report(loadingRecentPage)

  # step 3: the remaining downloaded languages, unawaited, 3 at a time
  unawaited(_loadRemainingLanguages(...))
  unawaited(backgroundSchedulerProvider.notifier.schedule())

  return navigateTo
```

The first `await` in `init()` is what makes the loading spinner appear; once `init()` resolves, `Navigator.pushReplacementNamed` jumps to the chosen route, so the user never sees the home screen flash.

### Why the loading is staged

Fully loading all 34 languages before the first frame is what made cold start feel broken on slow Android devices (see [in_progress_notes/investigation_cold_start.md](in_progress_notes/investigation_cold_start.md)): the cost grew linearly with the number of downloaded languages while the spinner sat frozen.

Only the app language (for the menu) and the language of the resumed worksheet are needed before navigating; `lazyInit()` gives the *downloaded* flag for all the others, which is all the routing decision needs. Everything else is loaded afterwards — the widgets that use it (language selection menu, the drawer's translate icons) are driven by `languageProvider` and rebuild by themselves as languages arrive.

Step 3 gets the `LanguageController`s handed to it rather than the `WidgetRef`: `StartupPage` is disposed by `pushReplacementNamed` while that work is still running, and a disposed `WidgetRef` must not be used.

### Telling the user which stage we're in

On a slow device a single stage can take seconds, and a static caption then looks like a hang. So `init()` reports a `StartupStage` (`lib/data/startup_stage.dart`, exposed as `startupStageProvider`) right before it starts each stage, and the caption under the spinner renders the localized name of that stage. The rule is: only report a stage the code is actually in. That is why `loadingRecentPage` is reported from a continuation of the app language's `init()` and only if the worksheet's language is still loading at that moment - if it landed first there is nothing left to wait for and the caption stays on `loadingAppLanguage`.

Two consequences for the widget:
- Only the caption (a small `Consumer` inside `LoadingAnimation`) watches the provider, so a stage change rebuilds nothing but that text - in particular it never rebuilds `StartupPage` itself, which would restart `init()`.
- Riverpod forbids modifying a provider while the widget tree is building, so `StartupPage` is a `ConsumerStatefulWidget` that starts `init()` from a microtask in `initState`: the first frame (spinner, generic `loading` caption) goes out, then `init()` runs.

## Navigation primitives

- **`Navigator.pushNamed`** for normal in-app navigation.
- **`Navigator.pushReplacementNamed`** for the onboarding flow and the post-startup redirect, so the user can't go "back" into the loading screen.
- **`Navigator.popAndPushNamed`** when switching to a different translation of the same worksheet via the in-drawer translate icon.

## Persisting "recent"

Whenever `ViewPage` successfully renders a page it writes:
```dart
ref.read(sharedPrefsProvider).setString('recentPage', page);
ref.read(sharedPrefsProvider).setString('recentLang', langCode);
```
This is the state that `StartupPage` later reads to resume.

## Adding a route — checklist

1. Add a new branch in `generateRoutes()`.
2. Create the page widget in `lib/routes/` (or a feature subfolder).
3. Decide whether the route should appear in the drawer (`lib/widgets/main_drawer.dart`).
4. If the route takes path parameters (like `/view/`), parse them with `settings.name!.split('/')` and validate that all parts are non-empty before dispatching; otherwise fall through to the `ErrorPage` (or redirect to `/home` if it's a deep link from outside).
5. Add tests in `test/routes_test.dart` (uses a `TestObserver` `NavigatorObserver`).
