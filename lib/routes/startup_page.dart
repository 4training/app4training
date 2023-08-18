import 'dart:async';
import 'package:flutter/material.dart';
import 'package:four_training/routes/routes.dart';
import 'package:four_training/widgets/loading_animation.dart';

/// Handles the initial route "/":
/// Currently shows a loading indication while we're initializing
/// the data in the background.
class StartupPage extends StatefulWidget {
  /// The function that does all initialization asynchronously
  /// and returns a Future
  final Function initFunction;
  const StartupPage({super.key, required this.initFunction});

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
                // This is actually never called because as soon
                // as we push the new route he's out of here...
                return loadingAnimation("Redirecting ...");
              }
          }
        });
  }
}
