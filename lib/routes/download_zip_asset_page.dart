import 'dart:async';
import 'dart:io';
import 'package:download_assets/download_assets.dart';
import 'package:flutter/material.dart';
import 'package:four_training/data/globals.dart';
import 'package:four_training/utils/page_storage.dart';
import 'package:four_training/widgets/loadingAnimation.dart';

import 'assets_page.dart';

class DownloadZipAssetPage extends StatefulWidget {
  const DownloadZipAssetPage(
      {super.key, required this.title, required this.storage});
  final String title;
  final LocalPageStorage storage;

  @override
  State<DownloadZipAssetPage> createState() => _DownloadZipAssetPageState();
}

class _DownloadZipAssetPageState extends State<DownloadZipAssetPage> {
  List<DownloadAssetsController> downloadAssetsControllers = [
    DownloadAssetsController(),
    DownloadAssetsController()
  ];
  String message = "Press the download to start download";
  List<bool> downloaded = [false, false];
  String state = "Initializing";

  Future<dynamic>? _htmlData;
  final List<String> _lang = ["en", "de"];
  final String _urlStart = "https://github.com/holybiber/test-html-";
  final String _urlEnd = "/archive/refs/heads/main.zip";
  final String _pathStart = "/test-html-";
  final String _pathEnd = "-main";

  @override
  void initState() {
    super.initState();

    _init().then((value) {
      _htmlData = _downloadAssets();
      });
  }

  Future _init() async {
    debugPrint("initializing");
    // Setting the languagesPaths length to the number of languages
    languagePaths.length = _lang.length;

    // for each language we do the following ...
    for (int i = 0; i < downloadAssetsControllers.length; i++) {

      // Initialize the downloadAssetsController with a custom assetsDir for each language
      String assetsDir = "assets-${_lang[i]}";
      await downloadAssetsControllers[i].init(assetDir: assetsDir);

      // Then we check, if that dir already exists, meaning it is already donwloaded
      downloaded[i] =
      await downloadAssetsControllers[i].assetsDirAlreadyExists();
      debugPrint("assets (${_lang[i]})loaded: ${downloaded[i]}");

      // Now we store the full path to the language in the languagesPaths global
      languagePaths[i] = downloadAssetsControllers[i].assetsDir! +
          _pathStart +
          _lang[i] +
          _pathEnd;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _htmlData?.then((value) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (context) => AssetsPage(
                    title: 'Assets Page (${_lang[0]})',
                  )));
        }),
        initialData: "Loading",
        builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
          debugPrint(snapshot.connectionState.toString());

          switch (snapshot.connectionState) {
            case ConnectionState.none:
              return loadingAnimation("State: ${snapshot.connectionState}");
            case ConnectionState.waiting:
              return loadingAnimation("Loading: $state");
            case ConnectionState.active:
              return loadingAnimation("State: ${snapshot.connectionState}");
            case ConnectionState.done:
              if (snapshot.hasError) {
                return loadingAnimation(snapshot.error.toString());
              } else if (snapshot.hasData) {
                return loadingAnimation("Done");
              } else {
                return loadingAnimation("Empty Data");
              }
            default:
              return loadingAnimation("State: ${snapshot.connectionState}");
          }
        });
  }

  Future _refresh() async {
    state = "refreshing assets (delete and display)";
    debugPrint(state);
    downloadAssetsControllers.forEach((controller) async {
      await controller.clearAssets();
    });
  }

  Future _clear() async {
    state = "clearing assets";
    debugPrint(state);
    downloadAssetsControllers.forEach((controller) async {
      await controller.clearAssets();
    });
  }

  Future _downloadAssets() async {
    debugPrint("downloading assets");
    state = "downloading assets";
    debugPrint(_lang[0]);
    for (int i = 0; i < _lang.length; i++) {
      debugPrint("hi");
      if (downloaded[i]) {
        debugPrint("${_lang[i]} already downloaded. Continue ...");
        continue;
      } else {
        debugPrint("Start downloading ${_lang[i]} ...");
      }

      try {
        await downloadAssetsControllers[i].startDownload(
          assetsUrl: _urlStart + _lang[i] + _urlEnd,
          onProgress: (progressValue) {
            downloaded[i] = false;
            if (progressValue < 100) {
              String progress = "Downloading ${_lang[i]}: ";

              for (int i = 0; i < 100; i++) {
                if (i <= progressValue) {
                  progress += "|";
                } else {
                  progress += ".";
                }
              }

              // message = "Downloading - $progress";
              debugPrint(progress);
              state = progress;
            } else {
              message = "Download completed";
              state = "Download completed";
              debugPrint(message);
              downloaded[i] = true;
            }
          },
        );
      } on DownloadAssetsException catch (e) {
        debugPrint(e.toString());
        downloaded[i] = false;
      }
    }
  }


}
