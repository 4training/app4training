import 'dart:async';
import 'dart:io';
import 'package:download_assets/download_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:four_training/utils/page_storage.dart';

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
    DownloadAssetsController(), DownloadAssetsController()
  ];
  String message = "Press the download to start download";
  List<bool> downloaded = [false, false];
  String state = "Initializing";

  Future<String>? _htmlData;
  final List<String> _lang = ["en", "de"];
  final String _urlStart = "https://github.com/holybiber/test-html-";
  final String _urlEnd = "/archive/refs/heads/main.zip";
  final String _pathStart = "/test-html-";
  final String _pathEnd = "-main";

  @override
  void initState() {
    super.initState();

    _init().then((value) {
      _htmlData = _downloadAssets().then((_) {
        return _displayAssets();
      });
    });
  }

  Future _init() async {
    debugPrint("initializing");
    for (int i = 0; i < downloadAssetsControllers.length; i++) {
      String assetsDir = "assets-${_lang[i]}";
      await downloadAssetsControllers[i].init(assetDir: assetsDir);
      downloaded[i] =
          await downloadAssetsControllers[i].assetsDirAlreadyExists();
      debugPrint("assets (${_lang[i]})loaded: ${downloaded[i]}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _htmlData?.then((value) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (context) => AssetsPage(
                    htmlContent: value.toString(),
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
                return loadingAnimation(
                    "Empty Data"); // TODO - why ist this showing up during launch?
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
      await _displayAssets();
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

  Future<String> _displayAssets() async {
    state = "displaying assets";
    debugPrint(state);
    String htmlData = "";

    downloaded[0] = await downloadAssetsControllers[0].assetsDirAlreadyExists();
    if (!downloaded[0]) {
      debugPrint("re-downloading");
      await _downloadAssets();
    }

    state = "Creating html data ...";
    debugPrint(state);

    try {
      String path = downloadAssetsControllers[0].assetsDir! +
          _pathStart +
          _lang[0] +
          _pathEnd;

      debugPrint(path);
      var dir = Directory(path);

      await for (var file in dir.list(recursive: false, followLinks: false)) {
        if (file.statSync().type == FileSystemEntityType.file) {
          htmlData += await File(file.path).readAsString();
        }
      }

      state = "Finished creating html data";
      debugPrint(state);
    } catch (e) {
      String msg = e.toString();
      htmlData = "<p>$msg</p>";

      state = "Error creating html data";
      debugPrint(state);
    }
    return htmlData;
  }

  Widget loadingAnimation(String msg) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            flex: 10,
            child: Container(),
          ),
          const Expanded(child: CircularProgressIndicator()),
          Expanded(child: Container()),
          Expanded(child: Text(msg)),
          Expanded(
            flex: 10,
            child: Container(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refresh,
        child: Icon(Icons.delete),
      ),
    );
  }
}
