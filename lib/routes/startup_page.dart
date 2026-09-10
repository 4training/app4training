import 'dart:async';
import 'dart:collection';

import 'package:app4training/background/background_scheduler.dart';
import 'package:app4training/data/app_language.dart';
import 'package:app4training/features/perf/perf_logger.dart';
import 'package:app4training/routes/error_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app4training/widgets/loading_animation.dart';

import '../data/globals.dart';
import '../data/languages.dart';

/// How many languages to load in parallel after the first screen is up
const int _maxParallelLanguageLoads = 3;

/// Handle the initial route "/": Show a loading indicator
/// while we're initializing the data in the background.
/// In case the user is new: Lead him to the onboarding / resume onboarding
/// in case onboarding got interrupted in between
class StartupPage extends ConsumerWidget {
  final Function? initFunction; // For testing (is there a better solution?)
  const StartupPage({super.key, this.initFunction});

  /// Initialize and return the route where to continue now
  ///
  /// This runs while the user is staring at the loading spinner, so it does
  /// as little work as possible before it can hand over to the first real
  /// screen (see docs/in_progress_notes/investigation_cold_start.md):
  ///
  /// 1. [LanguageController.lazyInit] for every language - one stat() each,
  ///    which is all we need to decide where to navigate to.
  /// 2. A full [LanguageController.init] for the one or two languages the
  ///    first screen actually renders.
  /// 3. The remaining downloaded languages are loaded afterwards, in the
  ///    background: nothing on the first screen depends on them, and the
  ///    widgets that do (language selection, drawer translation icons)
  ///    rebuild by themselves once a language arrives.
  Future<String> init(WidgetRef ref) async {
    if (ref.read(sharedPrefsProvider).getString('appLanguage') == null) {
      // First app usage: Let's start onboarding
      return '/onboarding/1';
    }

    // Step 1: Which languages are on the device?
    final List<String> availableLanguages =
        ref.read(availableLanguagesProvider);
    await PerfLogger.span(
        'startup.lazyInitAll',
        () => Future.wait([
              for (String languageCode in availableLanguages)
                ref.read(languageProvider(languageCode).notifier).lazyInit()
            ]),
        data: () => {'languages': availableLanguages.length});

    // Check whether app language is downloaded
    final String appLangCode = ref.read(appLanguageProvider).languageCode;
    if (!ref.read(languageProvider(appLangCode)).downloaded) {
      return '/onboarding/2'; // Go to DownloadLanguagesPage
    }

    /*  TODO for version 0.9
    // Check whether user completed third onboarding step
    if (ref.read(sharedPrefsProvider).getString('checkFrequency') == null) {
      return '/onboarding/3';
    }*/

    // Go to recently opened page or to /home
    String navigateTo = '/home';
    String page = ref.read(sharedPrefsProvider).getString('recentPage') ?? '';
    String lang = ref.read(sharedPrefsProvider).getString('recentLang') ?? '';
    final bool resumeRecentPage = (page != '') &&
        (lang != '') &&
        ref.read(languageProvider(lang)).downloaded;
    if (resumeRecentPage) navigateTo = '/view/$page/$lang';

    // Step 2: Load what the first screen needs - the app language for the menu
    // and, if we resume a recent page, the language that page is written in.
    final Set<String> neededNow = {appLangCode, if (resumeRecentPage) lang};
    await PerfLogger.span(
        'startup.initNeededNow',
        () => Future.wait([
              for (String languageCode in neededNow)
                ref.read(languageProvider(languageCode).notifier).init()
              // TODO: look at return value and show snackBar on error
            ]),
        data: () => {'languages': neededNow.length});

    // Step 3: Everything else may take its time. We hand over the controllers
    // rather than the WidgetRef: this page is disposed as soon as we navigate
    // away, and a disposed WidgetRef must not be used any more.
    unawaited(_loadRemainingLanguages([
      for (String languageCode in availableLanguages)
        if (!neededNow.contains(languageCode) &&
            ref.read(languageProvider(languageCode)).downloaded)
          ref.read(languageProvider(languageCode).notifier)
    ]));

    // Start the periodic background task
    unawaited(ref.read(backgroundSchedulerProvider.notifier).schedule());

    // Only the kind of destination - never which page/language (no PII)
    PerfLogger.event('startup.navigate',
        data: {'destination': resumeRecentPage ? 'view' : 'home'});
    return navigateTo;
  }

  /// Fully load the languages behind [controllers], a few at a time.
  ///
  /// Runs after the first screen is on its way, with a small concurrency
  /// limit so we don't flood the IO queue of a slow device while it is still
  /// busy rendering that screen.
  Future<void> _loadRemainingLanguages(
      List<LanguageController> controllers) async {
    final pending = Queue<LanguageController>.of(controllers);

    Future<void> worker() async {
      while (pending.isNotEmpty) {
        await pending.removeFirst().init();
      }
    }

    await PerfLogger.span(
        'startup.loadRemaining',
        () => Future.wait(
            [for (var i = 0; i < _maxParallelLanguageLoads; i++) worker()]),
        data: () => {'languages': controllers.length});
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // When we're finished with loading: Go to the recently opened page
    Future<String> initResult =
        ((initFunction != null) ? initFunction!() : init(ref));
    return FutureBuilder(
      future: initResult.then(
        (String navigateTo) => {
          if (context.mounted)
            {Navigator.pushReplacementNamed(context, navigateTo)},
        },
      ),
      initialData: "Loading",
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (kDebugMode) debugPrint(snapshot.connectionState.toString());

        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
          case ConnectionState.active:
            return loadingAnimation('Loading');
          case ConnectionState.done:
            if (kDebugMode) {
              debugPrint('Done, hasData: ${snapshot.hasData},'
                  ' Error: ${snapshot.hasError}');
            }
            if (snapshot.hasError) {
              // TODO do something more helpful for the user ("try again...")
              return ErrorPage(snapshot.error.toString());
            } else {
              // This is actually never called because as soon
              // as we push the new route he's out of here...
              return loadingAnimation('Redirecting ...');
            }
        }
      },
    );
  }
}
