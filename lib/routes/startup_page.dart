import 'dart:async';
import 'dart:collection';

import 'package:app4training/background/background_scheduler.dart';
import 'package:app4training/data/app_language.dart';
import 'package:app4training/data/startup_stage.dart';
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
class StartupPage extends ConsumerStatefulWidget {
  final Function? initFunction; // For testing (is there a better solution?)
  const StartupPage({super.key, this.initFunction});

  @override
  ConsumerState<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends ConsumerState<StartupPage> {
  /// Completes once we have pushed the next route (or with init()'s error)
  late final Future<void> _navigation;

  @override
  void initState() {
    super.initState();
    // init() reports where it is through startupStageProvider, and a provider
    // must not be modified while the widget tree is building. So the first
    // frame (spinner with its initial caption) goes out before init() starts.
    _navigation = Future.microtask(() {
      final Future<String> initResult =
          (widget.initFunction != null) ? widget.initFunction!() : init();
      return initResult;
    }).then((String navigateTo) {
      if (!mounted) return;
      unawaited(Navigator.pushReplacementNamed(context, navigateTo));
    });
  }

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
  Future<String> init() async {
    if (ref.read(sharedPrefsProvider).getString('appLanguage') == null) {
      // First app usage: Let's start onboarding
      return '/onboarding/1';
    }
    final StartupStageNotifier stage = ref.read(startupStageProvider.notifier);

    // Step 1: Which languages are on the device?
    stage.report(StartupStage.checkingLanguages);
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
    stage.report(StartupStage.loadingAppLanguage);
    final Set<String> neededNow = {appLangCode, if (resumeRecentPage) lang};
    final Future<bool> appLanguageLoaded =
        ref.read(languageProvider(appLangCode).notifier).init();
    final List<Future<bool>> loads = [appLanguageLoaded];
    if (neededNow.length > 1) {
      // Both load in parallel. Once the app language is in, all we're still
      // waiting for is the worksheet's language - but only say so if that
      // one is in fact still loading.
      bool recentLanguageLoaded = false;
      loads.add(ref
          .read(languageProvider(lang).notifier)
          .init()
          .whenComplete(() => recentLanguageLoaded = true));
      unawaited(appLanguageLoaded.then((_) {
        if (!recentLanguageLoaded) stage.report(StartupStage.loadingRecentPage);
      }, onError: (_) {})); // errors surface through the Future.wait below
    }
    // TODO: look at the return values and show snackBar on error
    await PerfLogger.span('startup.initNeededNow', () => Future.wait(loads),
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
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _navigation,
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        if (kDebugMode) debugPrint(snapshot.connectionState.toString());

        if (snapshot.hasError) {
          // TODO do something more helpful for the user ("try again...")
          return ErrorPage(snapshot.error.toString());
        }
        // Once init() is done we have already pushed the next route; this
        // page just stays as it is while that route animates in.
        return const LoadingAnimation(caption: _StartupCaption());
      },
    );
  }
}

/// Names the stage init() is in. Watching the stage here, and only here,
/// keeps a stage change from rebuilding anything but this text.
class _StartupCaption extends ConsumerWidget {
  const _StartupCaption();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Text(
        StartupStage.getLocalized(context, ref.watch(startupStageProvider)));
  }
}
