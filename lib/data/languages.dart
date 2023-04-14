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
  String htmlData = "";
  bool downloaded = false;
  DownloadAssetsController controller = DownloadAssetsController();
  List<dynamic> pages = [];
  List<dynamic> resources = [];
  List<dynamic> structure = [];

  Language(this.lang);

  Future init() async {
    // Initialize the downloadAssetsController with a custom assetsDir for each language
    String assetsDir = "assets-$lang";
    await controller.init(assetDir: assetsDir);

    // Now we store the full path to the language
    path = controller.assetsDir! + pathStart + lang + pathEnd;
    src = urlStart + lang + urlEnd;

    // Then we check, if that dir already exists, meaning it is already downloaded
    downloaded = await controller.assetsDirAlreadyExists();
    debugPrint("assets ($lang) loaded: $downloaded");
    if (!downloaded) await download();

    pages = await initPages();
    structure = await initStructure();
    sortPages();
    await initResources();
  }

  Future download() async {
    debugPrint("Starting downloadLanguage: $lang ...");

    if (downloaded) {
      debugPrint("$lang already downloaded. Continue ...");
      return;
    }

    debugPrint("Start downloading $lang ...");

    try {
      await controller.startDownload(
        assetsUrl: src,
        onProgress: (progressValue) {
          if (progressValue < 20) {
            // The value goes for some reason only up to 18.7 or so ...
            String progress = "Downloading $lang: ";

            for (int i = 0; i < 20; i++) {
              if (i <= progressValue) {
                progress += "|";
              } else {
                progress += ".";
              }
            }

            debugPrint(progress);
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

    debugPrint("Done downloadLanguage: $lang ...");
  }

  Future<List<dynamic>> initPages() async {
    List<dynamic> fileNames = [];

    try {
      var dir = Directory(path);

      await for (var file in dir.list(recursive: false, followLinks: false)) {
        if (file is File) {
          String fileName = basename(file.path);
          fileNames.add(fileName);
        }
      }
      return fileNames;
    } catch (e) {
      String msg = "Error creating fileNames: $e";
      debugPrint(msg);
      return Future.error(msg);
    }
  }

  Future<List<dynamic>> initStructure() async {
    var data = [];

    try {
      Directory dir = Directory(path);

      await for (var directory
          in dir.list(recursive: false, followLinks: false)) {
        if (directory is Directory) {
          String directoryName = basename(directory.path);
          if (directoryName == "structure") {
            Directory d = directory;
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
    if (structure.isEmpty) {
      debugPrint("Structure List is empty.");
      return;
    }

    if (pages.isEmpty) {
      debugPrint("Pages List is empty.");
      return;
    }

    List<dynamic> sortedPages = [];

    for (Map element in structure) {
      element.forEach((key, value) {
        sortedPages.add(value);
      });
    }
    bool allPagesFound = true;
    for (var page in pages) {
      bool contains = sortedPages.contains(page);
      if (!contains) {
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

  Future initResources() async {} // TODO

  Future<dynamic> displayPage() async {
    String htmlData = "";
    String pageName = pages.elementAt(currentIndex);
    debugPrint("Displaying the page '$pageName' (language: $lang, index: $currentIndex)");

    try {
      var dir = Directory(path);

      await for (var file in dir.list(recursive: false, followLinks: false)) {
        if (file is File) {
          String fileName = basename(file.path);
          if(pageName == fileName) {
            htmlData = await File(file.path).readAsString();
            break;
          }
        }
      }

      debugPrint("Finished creating html data");
      return htmlData;
    } catch (e) {
      String msg = e.toString();

      debugPrint("Error creating html data. $msg");

      return Future.error(msg);
    }
  }
}
