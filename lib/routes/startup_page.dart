import 'dart:async';
import 'package:app4training/background/background_scheduler.dart';
import 'package:app4training/data/app_language.dart';
import 'package:app4training/routes/error_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app4training/widgets/loading_animation.dart';

import '../data/globals.dart';
import '../data/languages.dart';

/// Handle the initial route "/": Show a loading indicator
/// while we're initializing the data in the background.
/// In case the user is new: Lead him to the onboarding / resume onboarding
/// in case onboarding got interrupted in between
class StartupPage extends ConsumerWidget {
  final Function? initFunction; // For testing (is there a better solution?)
  const StartupPage({super.key, this.initFunction});

  /// Initialize and return the route where to continue now
  Future<String> init(WidgetRef ref) async {
    if (ref.read(sharedPrefsProvider).getString('appLanguage') == null) {
      // First app usage: Let's start onboarding
      return '/onboarding/1';
    }

    // Read downloaded languages from the device
    for (String languageCode in ref.read(availableLanguagesProvider)) {
      await ref.read(languageProvider(languageCode).notifier).init();
      // TODO: look at return value and show snackBar when there was an error
    }

    // Check whether app language is downloaded
    if (!ref
        .read(languageProvider(ref.read(appLanguageProvider).languageCode))
        .downloaded) {
      return '/onboarding/2'; // Go to DownloadLanguagesPage
    }

/*  TODO for version 0.9
    // Check whether user completed third onboarding step
    if (ref.read(sharedPrefsProvider).getString('checkFrequency') == null) {
      return '/onboarding/3';
    }*/

    // Start the periodic background task
    unawaited(ref.read(backgroundSchedulerProvider.notifier).schedule());

    // Go to recently opened page or to /home
    String navigateTo = '/home';
    String page = ref.read(sharedPrefsProvider).getString('recentPage') ?? '';
    String lang = ref.read(sharedPrefsProvider).getString('recentLang') ?? '';
    if ((page != '') &&
        (lang != '') &&
        ref.read(languageProvider(lang)).downloaded) {
      navigateTo = '/view/$page/$lang';
    }
    return navigateTo;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // When we're finished with loading: Go to the recently opened page
    Future<String> initResult =
        ((initFunction != null) ? initFunction!() : init(ref));
    return FutureBuilder(
        future: initResult.then((String navigateTo) =>
            Navigator.pushReplacementNamed(context, navigateTo)),
        initialData: "Loading",
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          debugPrint(snapshot.connectionState.toString());

          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
            case ConnectionState.active:
              return loadingAnimation('Loading');
            case ConnectionState.done:
              debugPrint(
                  'Done, hasData: ${snapshot.hasData}, Error: ${snapshot.hasError}');
              if (snapshot.hasError) {
                // TODO do something more helpful for the user ("try again...")
                return ErrorPage(snapshot.error.toString());
              } else {
                // This is actually never called because as soon
                // as we push the new route he's out of here...
                return loadingAnimation('Redirecting ...');
              }
          }
        });
  }
}
