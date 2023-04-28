import 'dart:async';
import 'package:flutter/material.dart';
import 'package:four_training/widgets/loading_animation.dart';
import 'package:four_training/utils/assets_handler.dart';

class StartupPage extends StatefulWidget {
  const StartupPage({super.key, required this.title});
  final String title;

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  late Future<dynamic> _data;

  @override
  void initState() {
    super.initState();
    _data = init();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _data.then((v) => Navigator.pushReplacementNamed(context, "/asset")),
        initialData: "Loading",
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          debugPrint(snapshot.connectionState.toString());

          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
            case ConnectionState.active:
              return loadingAnimation("Loading");
            case ConnectionState.done:
              if (snapshot.hasError) {
                return loadingAnimation(snapshot.error.toString());
              } else if (snapshot.hasData) {
                return loadingAnimation("Redirecting ...");
              } else {
                debugPrint(snapshot.data);
                debugPrint(snapshot.error.toString());
                return loadingAnimation("Empty Data");
              }
            default:
              return loadingAnimation("State: ${snapshot.connectionState}");
          }
        });
  }

  Future<dynamic> init() async {
    debugPrint("Download Assets Page");
    return await initAssets();
  }
}
