import 'dart:async';
import 'package:flutter/material.dart';
import 'package:four_training/widgets/loading_animation.dart';
import 'assets_page.dart';
import 'package:four_training/utils/assets_handler.dart';

class DownloadZipAssetPage extends StatefulWidget {
  const DownloadZipAssetPage({super.key, required this.title});
  final String title;

  @override
  State<DownloadZipAssetPage> createState() => _DownloadZipAssetPageState();
}

class _DownloadZipAssetPageState extends State<DownloadZipAssetPage> {

  late Future<dynamic> _data;

  @override
  void initState() {
    super.initState();
    _data = init();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _data.then((value) => Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => const AssetsPage()))),
        initialData: "Loading",
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          debugPrint(snapshot.connectionState.toString());

          switch (snapshot.connectionState) {
            case ConnectionState.none:
              return loadingAnimation("State: ${snapshot.connectionState}");
            case ConnectionState.waiting:
              return loadingAnimation("Loading");
            case ConnectionState.active:
              return loadingAnimation("State: ${snapshot.connectionState}");
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
    debugPrint("Download Asstes Page");
    return await initAssets();
  }




}
