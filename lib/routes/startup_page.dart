import 'dart:async';
import 'package:app4training/routes/error_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app4training/widgets/loading_animation.dart';

import '../data/globals.dart';
import '../data/languages.dart';

/// Handles the initial route "/":
/// Currently shows a loading indication while we're initializing
/// the data in the background.
class StartupPage extends ConsumerStatefulWidget {
  final String navigateTo;
  final Function? initFunction; // For testing (is there a better solution?)
  const StartupPage({required this.navigateTo, super.key, this.initFunction});

  @override
  ConsumerState<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends ConsumerState<StartupPage> {
  late String navigateTo = widget.navigateTo;

  /// Make sure we have all the resources downloaded in the languages we want
  /// and load the structure
  Future initResources(WidgetRef ref) async {
    for (String languageCode in ref.read(availableLanguagesProvider)) {
      await ref.read(languageProvider(languageCode).notifier).init();
      // TODO: look at return value and show snackBar when there was an error
    }
    if (ref.read(countDownloadedLanguagesProvider) == 0) {
      navigateTo = '/downloadlanguages';
    }
  }

  @override
  Widget build(BuildContext context) {
    // When we're finished with loading: Go to the recently opened page
    Future initResult = ((widget.initFunction != null)
        ? widget.initFunction!()
        : initResources(ref));
    return FutureBuilder(
        future: initResult
            .then((v) => Navigator.pushReplacementNamed(context, navigateTo)),
        initialData: "Loading",
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          debugPrint(snapshot.connectionState.toString());

          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
            case ConnectionState.active:
              return loadingAnimation("Loading");
            case ConnectionState.done:
              debugPrint(
                  'Done, hasData: ${snapshot.hasData}, Error: ${snapshot.hasError}');
              if (snapshot.hasError) {
                // TODO do something more helpful for the user ("try again...")
                return ErrorPage(snapshot.error.toString());
              } else {
                // This is actually never called because as soon
                // as we push the new route he's out of here...
                return loadingAnimation("Redirecting ...");
              }
          }
        });
  }
}
