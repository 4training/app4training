import 'dart:async';
import 'package:app4training/routes/error_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app4training/widgets/loading_animation.dart';

import '../data/globals.dart';
import '../data/languages.dart';

/// Handles the initial route "/":
/// Currently shows a loading indication while we're initializing
/// the data in the background.
class StartupPage extends ConsumerWidget {
  final Function? initFunction; // For testing (is there a better solution?)
  const StartupPage({super.key, this.initFunction});

  /// Make sure we have all the resources downloaded in the languages we want
  /// and load the structure.
  /// Returns the route where to continue now
  Future<String> initResources(WidgetRef ref) async {
    for (String languageCode in ref.read(availableLanguagesProvider)) {
      await ref.read(languageProvider(languageCode).notifier).init();
      // TODO: look at return value and show snackBar when there was an error
    }
    // TODO: Check more specifically whether app language is available
    if (ref.read(countDownloadedLanguagesProvider) == 0) {
      return '/onboarding/2';
    }

    String page = ref.read(sharedPrefsProvider).getString('recentPage') ?? '';
    String lang = ref.read(sharedPrefsProvider).getString('recentLang') ?? '';
    String navigateTo = '/home';
    if ((page != '') &&
        (lang != '') &&
        ref.read(availableLanguagesProvider).contains(lang)) {
      navigateTo = '/view/$page/$lang';
    }
    return navigateTo;
  }

  /// Check and return: Did user complete onboarding?
  /// If not, push the onboarding route
  bool passOnboarding(BuildContext context, WidgetRef ref) {
    if (ref.read(sharedPrefsProvider).getString('appLanguage') == null) {
      // First the StartupPage needs to be built before we can push a new route,
      // that's why we need to use addPostFrameCallback
      SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
        // First app usage: Let's start onboarding
        Navigator.pushReplacementNamed(context, '/onboarding/1');
      });
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!passOnboarding(context, ref)) return const Text('');
    // When we're finished with loading: Go to the recently opened page
    Future<String> initResult =
        ((initFunction != null) ? initFunction!() : initResources(ref));
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
