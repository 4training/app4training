import 'dart:convert';
import 'dart:io';
import 'package:download_assets/download_assets.dart';
import 'package:flutter/cupertino.dart';
import 'package:four_training/data/globals.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;

class Worksheet {
  String page; // English worksheet name
  String title; // translated title
  String? content; // HTML code of this worksheet (loaded on demand)
  Worksheet(this.page, this.title);
  //  String version;
}

class Language {
  final String languageCode;

  /// URL of the zip file to be downloaded
  final String remoteUrl;

  /// full local path to directory holding all content
  late final String path;

  /// Directory object of path
  late final Directory _dir;

  bool downloaded = false;
  List<List<String>> pages = [];
  List<List<String>> resources = [];
  List<dynamic> structure = [];
  DateTime? _timestamp;
  int commitsSinceDownload = 0;
  final DownloadAssetsController _controller = DownloadAssetsController();

  Language(this.languageCode) : remoteUrl = urlStart + languageCode + urlEnd;

  Future init() async {
    await _controller.init(assetDir: "assets-$languageCode");

    // Now we store the full path to the language
    path = _controller.assetsDir! + pathStart + languageCode + pathEnd;
    _dir = Directory(path);
    debugPrint("Path: $path");

    // Then we check, if that dir already exists, meaning it is already downloaded
    downloaded = await _controller.assetsDirAlreadyExists();
    debugPrint("assets ($languageCode) loaded: $downloaded");
    // TODO properly check whether we already downloaded the assets
    await _download();

    _timestamp = await _getTimestamp();
    commitsSinceDownload = await _fetchLatestCommits();
    pages = await _initPages();
    structure = await _initStructure();
    _sortPages();
    resources = await _initResources();
    _fixHtml();
  }

  Future _download() async {
    debugPrint("Starting downloadLanguage: $languageCode ...");

/*    if (downloaded) {
      debugPrint("$languageCode already downloaded. Continue ...");
      return;
    }*/

    try {
      await _controller.startDownload(
        assetsUrls: [remoteUrl],
        onProgress: (progressValue) {
          if (progressValue < 20) {
            // The value goes for some reason only up to 18.7 or so ...
            String progress = "Downloading $languageCode: ";

            for (int i = 0; i < 20; i++) {
              progress += (i <= progressValue) ? "|" : ".";
            }
            //debugPrint("$progress ${progressValue.round()}");
          } else {
            debugPrint("Download completed");
            downloaded = true;
          }
        },
      );
    } on DownloadAssetsException catch (e) {
      debugPrint(e.toString());
      downloaded = false;
    }
  }

  Future<void> removeAssets() async {
    await _controller.clearAssets();
  }

  Future<List<List<String>>> _initPages() async {
    debugPrint("init Pages: $languageCode");
    List<List<String>> pageData = [];

    try {
      await for (var file in _dir.list(recursive: false, followLinks: false)) {
        if (file is File) {
          String fileName = basename(file.path);
          String content = await file.readAsString();
          List<String> page = [fileName, content];
          pageData.add(page);
        }
      }
      return pageData;
    } catch (e) {
      String msg = "Error creating pageData: $e";
      debugPrint(msg);
      return Future.error(msg);
    }
  }

  Future<List<dynamic>> _initStructure() async {
    debugPrint("init Structure: $languageCode");
    var data = [];

    try {
      await for (var directory
          in _dir.list(recursive: false, followLinks: false)) {
        if (directory is Directory) {
          String directoryName = basename(directory.path);
          if (directoryName == "structure") {
            File structureFile = await directory.list().first as File;
            data = jsonDecode(structureFile.readAsStringSync());
          }
        }
      }
      return data;
    } catch (e) {
      String msg = "Error creating structure:$e";
      debugPrint(msg);
      return Future.error(msg);
    }
  }

  void _sortPages() {
    debugPrint("sort Pages: $languageCode");
    if (structure.isEmpty || pages.isEmpty) {
      debugPrint(
          "Something is empty (true) --> Structure: ${structure.isEmpty} | Pages: ${pages.isEmpty}");
      return;
    }

    List<List<String>> sortedPages = [];

    for (Map element in structure) {
      element.forEach((key, value) {
        String content = "";

        for (int i = 0; i < pages.length; i++) {
          String pageName = pages.elementAt(i).elementAt(0);

          if (value == pageName) {
            content = pages.elementAt(i).elementAt(1);
            break;
          }
        }

        List<String> sortedPage = [value, content];
        sortedPages.add(sortedPage);
      });
    }
    bool allPagesFound = true;

    for (int i = 0; i < pages.length; i++) {
      String pageName = pages.elementAt(i).elementAt(0);
      bool pageNameFoundInSortedList = false;
      for (int j = 0; j < sortedPages.length; j++) {
        String sortedName = sortedPages.elementAt(j).elementAt(0);

        if (pageName == sortedName) {
          pageNameFoundInSortedList = true;
          break;
        }
      }
      if (!pageNameFoundInSortedList) {
        allPagesFound = false;
        break;
      }
    }

    if (allPagesFound) {
      pages = sortedPages;
    } else {
      debugPrint("pages and sortedPages do not match");
    }
  }

  Future<List<List<String>>> _initResources() async {
    debugPrint("init Resources: $languageCode");
    List<List<String>> data = [];

    try {
      await for (var directory
          in _dir.list(recursive: false, followLinks: false)) {
        if (directory is Directory) {
          if (basename(directory.path) == "files") {
            debugPrint("found files");
            await directory.list().forEach((element) {
              String fileName = basename(element.path);
              String imageData = imageToBase64(element as File);
              var foo = [fileName, imageData];
              data.add(foo);
            });
          }
        }
      }
      return data;
    } catch (e) {
      String msg = "Error creating files:$e";
      debugPrint(msg);
      return Future.error(msg);
    }
  }

  void _fixHtml() {
    debugPrint("fix html: $languageCode");
    List<List<String>> fixedPages = [];

    for (int i = 0; i < pages.length; i++) {
      String fileName = pages.elementAt(i).elementAt(0);
      String content = pages.elementAt(i).elementAt(1);

      for (int j = 0; j < resources.length; j++) {
        String resourceName = resources.elementAt(j).elementAt(0);
        String imageData = resources.elementAt(j).elementAt(1);

        if (content.contains(resourceName)) {
          content = content.replaceAll(
              "files/$resourceName", "data:image/png;base64,$imageData");
        }
      }
      fixedPages.add([fileName, content]);
    }
    pages = fixedPages;
  }

  Future<DateTime> _getTimestamp() async {
    DateTime timestamp = DateTime.now();

    try {
      await for (var file in _dir.list(recursive: false, followLinks: false)) {
        if (file is File) {
          FileStat stat = await FileStat.stat(file.path);
          timestamp = stat.changed;
          break;
        }
      }
    } catch (e) {
      String msg = "Error getting timestamp: $e";
      debugPrint(msg);
      return Future.error(msg);
    }
    debugPrint(timestamp.toString());
    return timestamp;
  }

  /// Returns the timestamp in a human readable string. If we don't have a timestamp, an empty string is returned.
  String formatTimestamp() {
    if (_timestamp == null) return "";
    return DateFormat('yyyy-MM-dd HH:mm').format(_timestamp!);
  }

  Future<int> _fetchLatestCommits() async {
    if (_timestamp == null) {
      return Future.error("TODO");
    }
    var t = _timestamp!.subtract(const Duration(
        days: 500)); // TODO just for testing, use timestamp instead
    var uri = latestCommitsStart +
        languageCode +
        latestCommitsEnd +
        t.toIso8601String();
    debugPrint(uri);
    final response = await http.get(Uri.parse(uri));

    if (response.statusCode == 200) {
      // = OK response
      var data = json.decode(response.body);
      int commits = data.length;
      debugPrint(
          "Found $commits new commits since download on $t ($languageCode)");
      if (commits > 0) newCommitsAvailable = true;
      return commits;
    } else {
      return Future.error(
          "Failed to fetch latest commits ${response.statusCode}");
    }
  }

  /// Return the HTML code of the page identified by [index]
  /// TODO error handling / select by name instead of index?
  Future<String> getPageContent(int index) async {
    String pageName = pages.elementAt(index).elementAt(0);
    String pageContent = pages.elementAt(index).elementAt(1);
    debugPrint(
        "Displaying page '$pageName' (lang: $languageCode, index: $index)");
    return pageContent;
  }

  /// Returns a list with all the worksheet titles available.
  /// They are the names of the HTML files, e.g. "Hearing_from_God.html"
  List<String> getPageTitles() {
    List<String> titles = [];
    for (int i = 0; i < pages.length; i++) {
      titles.add(pages.elementAt(i).elementAt(0));
    }
    return titles;
  }

  /// Get the worksheet index for a given title.
  /// Returns null if it couldn't be found. Index starts with 0.
  int? getIndexByTitle(String title) {
    for (int i = 0; i < pages.length; i++) {
      if (pages.elementAt(i).elementAt(0) == title) {
        return i;
      }
    }
    return null;
  }
}

String imageToBase64(File image) {
  List<int> imageBytes = image.readAsBytesSync();
  return base64Encode(imageBytes);
}
