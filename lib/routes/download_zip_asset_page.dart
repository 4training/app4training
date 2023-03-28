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
  DownloadAssetsController downloadAssetsController =
      DownloadAssetsController();
  String message = "Press the download to start download";
  bool downloaded = false;
  String state = "Initializing";

  Future<String>? _htmlData;
  final String _url =
      "https://github.com/holybiber/test-html-en/archive/refs/heads/main.zip";

  @override
  void initState() {
    super.initState();

    _init().then((value) {
      _htmlData = _downloadAssets().then(_displayAssets()); // TODO
    });
  }

  Future _init() async {
    debugPrint("initializing");
    await downloadAssetsController.init();

    downloaded = await downloadAssetsController.assetsDirAlreadyExists();

    debugPrint("assets loaded: $downloaded");
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _htmlData?.then((value) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (context) => AssetsPage(
                    htmlContent: value.toString(),
                    title: 'Assets Page',
                  )));
        }),
        initialData: "Loading",
        builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
          debugPrint(snapshot.connectionState.toString());

          switch (snapshot.connectionState) {
            case ConnectionState.none:
              return loadingAnimation("State: ${snapshot.connectionState}");
            case ConnectionState.waiting:
              return loadingAnimation("Loading $state");
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
    await downloadAssetsController.clearAssets();
    await _displayAssets();
  }

  Future _clear() async {
    state = "clearing assets";
    debugPrint(state);
    await downloadAssetsController.clearAssets();
  }

  Future<String> _displayAssets() async {
    state = "displaying assets";
    debugPrint(state);
    String htmlData = "";

    downloaded = await downloadAssetsController.assetsDirAlreadyExists();
    if (!downloaded) await _downloadAssets();

    state = "Creating html data ...";
    debugPrint(state);

    try {
      String path = "${downloadAssetsController.assetsDir}/test-html-en-main/";

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

  Future _downloadAssets() async {
    debugPrint("downloading assets");
    state = "downloading assets";

    bool assetsDownloaded =
        await downloadAssetsController.assetsDirAlreadyExists();

    if (assetsDownloaded) return;

    try {
      await downloadAssetsController.startDownload(
        assetsUrl: _url,
        onProgress: (progressValue) {
          downloaded = false;
          if (progressValue < 100) {
            String progress = "Downloading: ";

            for (int i = 0; i < 100; i++) {
              if (i <= progressValue)
                progress += "|";
              else
                progress += ".";
            }

            // message = "Downloading - $progress";
            debugPrint(progress);
            state = progress;
          } else {
            message = "Download completed";
            state = "Download completed";
            debugPrint(message);
            downloaded = true;
          }
        },
      );
    } on DownloadAssetsException catch (e) {
      debugPrint(e.toString());
      downloaded = false;
    }
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
    ),);
  }
}
