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
| `/onboarding/3` | `SetUpdatePrefsPage` | Update preferences (currently bypassed in startup flow — gated for v0.9) |
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

  for each available language:
      ref.read(languageProvider(code).notifier).init()   # load disk state

  if app language is not yet downloaded:
      return '/onboarding/2'                 # resume onboarding

  # (commented out for v0.9: third onboarding step on missing checkFrequency)

  ref.read(backgroundSchedulerProvider.notifier).schedule()

  if SharedPreferences['recentPage'] && 'recentLang' && language is downloaded:
      return '/view/<recentPage>/<recentLang>'   # resume last worksheet
  return '/home'
```

The first `await` in `init()` is what makes the loading spinner appear; once `init()` resolves, `Navigator.pushReplacementNamed` jumps to the chosen route, so the user never sees the home screen flash.

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
