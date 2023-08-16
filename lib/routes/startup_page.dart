import 'dart:async';
import 'package:flutter/material.dart';
import 'package:four_training/data/globals.dart';
import 'package:four_training/routes/routes.dart';
import 'package:four_training/widgets/loading_animation.dart';

class StartupPage extends StatefulWidget {
  final Function initFunction;
  // The optional parameter initFunction is for testing
  const StartupPage({super.key, this.initFunction = globalInit});

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  late Future<dynamic> _data;

  @override
  void initState() {
    super.initState();
    _data = widget.initFunction();
  }

  @override
  Widget build(BuildContext context) {
    // Get the local language
    localLanguageCode = Localizations.localeOf(context).languageCode;

    return FutureBuilder(
        future:
            _data.then((v) => Navigator.pushReplacementNamed(context, "/view")),
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
                // TODO do something more helpful for the user
                return ErrorPage(snapshot.error.toString());
              } else {
                // This is actually never called because of the new route...
                return loadingAnimation("Redirecting ...");
              }
          }
        });
  }
}
