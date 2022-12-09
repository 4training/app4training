import 'dart:io';
import 'package:download_assets/download_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:four_training/utils/page_storage.dart';

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
  var _angle = 0.0;

  Future<String>? _htmlData;
  final String _url =
      "https://github.com/holybiber/test-html-en/archive/refs/heads/main.zip";

  @override
  void initState() {
    super.initState();

    _init().then((value) {
      _htmlData = _displayAssets();
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: _refresh,
                child: Transform.rotate(
                    angle: _angle,
                    child: const Icon(
                      Icons.refresh,
                      size: 26.0,
                    )),
              )),
        ],
      ),
      body: ListView(
        children: [
          FutureBuilder(
              future: _htmlData,
              initialData: "Loading",
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return  SizedBox( height: MediaQuery.of(context).size.height / 1.3, child: Center( child: CircularProgressIndicator()));
                } else if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasError) {
                    return Text(snapshot.error.toString());
                  } else if (snapshot.hasData) {
                    return SingleChildScrollView( child:Html(data: snapshot.data));
                  } else {
                    return const Text("Empty Data");
                  }
                } else {
                  return Text("State: ${snapshot.connectionState}");
                }
              }),
        ],
      ),
    );
  }

  Future _refresh() async {
    debugPrint("refreshing assets (delete and display)");
    await downloadAssetsController.clearAssets();
    await _displayAssets();
  }

  Future _clear() async {
    debugPrint("clearing assets");
    await downloadAssetsController.clearAssets();

  }

  Future<String> _displayAssets() async {
    debugPrint("displaying assets");
    String htmlData = "";

    downloaded = await downloadAssetsController.assetsDirAlreadyExists();
    if (!downloaded) await _downloadAssets();

    debugPrint("creating html data ...");

    try {

      String path = "${downloadAssetsController.assetsDir}/test-html-en-main/";

      var dir = Directory(path);

      await for (var file in dir.list(recursive: false, followLinks: false)) {

        if(file.statSync().type == FileSystemEntityType.file) {
        htmlData += await File(file.path).readAsString();}
      }

    } catch (e) {
      String msg = e.toString();
      htmlData = "<p>$msg</p>";
    }
    return htmlData;
  }

  Future _downloadAssets() async {
    debugPrint("downloading assets");

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
            _angle++;
            debugPrint(progress);
          } else {
            message = "Download completed";
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
}
