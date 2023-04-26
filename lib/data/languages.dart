import 'dart:convert';
import 'dart:io';
import 'package:download_assets/download_assets.dart';
import 'package:flutter/cupertino.dart';
import 'package:four_training/data/globals.dart';
import 'package:path/path.dart';

class Language {
  String lang;
  String src = "";
  String path = "";
  late Directory dir;
  bool downloaded = false;
  DownloadAssetsController controller = DownloadAssetsController();
  List<List<String>> pages = [];
  List<List<String>> resources = [];
  List<dynamic> structure = [];
  late DateTime timestamp;

  Language(this.lang);

  Future init() async {
    String assetDir = "assets-$lang";
    await controller.init(assetDir: assetDir);

    // Now we store the full path to the language
    path = controller.assetsDir! + pathStart + lang + pathEnd;
    dir = Directory(path);
    src = urlStart + lang + urlEnd;

    // Then we check, if that dir already exists, meaning it is already downloaded
    downloaded = await controller.assetsDirAlreadyExists();
    debugPrint("assets ($lang) loaded: $downloaded");
    if (!downloaded) await download();

    timestamp = await getTimestamp();
    pages = await initPages();
    structure = await initStructure();
    sortPages();
    resources = await initResources();
    fixHtml();
  }

  Future download() async {
    debugPrint("Starting downloadLanguage: $lang ...");

    if (downloaded) {
      debugPrint("$lang already downloaded. Continue ...");
      return;
    }

    try {
      await controller.startDownload(
        assetsUrl: src,
        onProgress: (progressValue) {
          if (progressValue < 20) { // The value goes for some reason only up to 18.7 or so ...
            String progress = "Downloading $lang: ";

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

  Future<List<List<String>>> initPages() async {
    debugPrint("init Pages: $lang");
    List<List<String>> pageData = [];

    try {
      await for (var file in dir.list(recursive: false, followLinks: false)) {
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

  Future<List<dynamic>> initStructure() async {
    debugPrint("init Structure: $lang");
    var data = [];

    try {
      await for (var directory
          in dir.list(recursive: false, followLinks: false)) {
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

  void sortPages() {
    debugPrint("sort Pages: $lang");
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

  Future<List<List<String>>> initResources() async {
    debugPrint("init Resources: $lang");
    List<List<String>> data = [];

    try {
      await for (var directory
          in dir.list(recursive: false, followLinks: false)) {
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

  void fixHtml() {
    debugPrint("fix html: $lang");
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

  Future<String> displayPage() async {
    String pageName = pages.elementAt(currentIndex).elementAt(0);
    String pageContent = pages.elementAt(currentIndex).elementAt(1);
    debugPrint(
        "Displaying page '$pageName' (lang: $lang, index: $currentIndex)");
    return pageContent;
  }

  Future<DateTime> getTimestamp() async {
    DateTime timestamp = DateTime.now();

    try {
      await for (var file in dir.list(recursive: false, followLinks: false)) {
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
}

String imageToBase64(File image) {
  List<int> imageBytes = image.readAsBytesSync();
  return base64Encode(imageBytes);
}
