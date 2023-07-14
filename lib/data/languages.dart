import 'dart:collection';
import 'dart:convert';
import 'package:download_assets/download_assets.dart';
import 'package:file/local.dart';
import 'package:flutter/cupertino.dart';
import 'package:four_training/data/globals.dart';
import 'package:file/file.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;

/// A page with HTML code: content is loaded on demand
class Page {
  /// English identifier
  final String name;

  /// (translated) Title
  final String title;

  /// (translated) Name of the HTML file
  final String fileName;

  final String version;

  /// HTML code of this page or null if not yet loaded
  String? content;

  Page(this.name, this.title, this.fileName, this.version);
}

/// Images to be used in pages: content is loaded on demand
class Image {
  final String name;

  /// Base64 encoded image content or null if not yet loaded
  String? data;

  Image(this.name);
}

/// late members will be initialized after calling init()
class Language {
  final String languageCode;

  /// URL of the zip file to be downloaded
  final String remoteUrl;

  /// full local path to directory holding all content
  late final String path;

  /// Directory object of path
  late final Directory _dir;

  bool downloaded = false;

  /// Holds our pages identified by their English name (e.g. "Hearing_from_God")
  final Map<String, Page> _pages = {};

  /// Define the order of pages in the menu: List of page names
  /// Not all pages must be in the menu, so every item in this list must be
  /// in _pages, but not every item of _pages must be in this list
  final List<String> _pageIndex = [];

  final Map<String, Image> _images = {};
  DateTime? _timestamp; // TODO
  int _commitsSinceDownload = 0; // TODO

  final DownloadAssetsController _controller;
  final FileSystem _fs;

  /// We use dependency injection (optional parameters [assetsController] and
  /// [fileSystem]) so that we can test the class well
  Language(this.languageCode,
      {DownloadAssetsController? assetsController, FileSystem? fileSystem})
      : remoteUrl = urlStart + languageCode + urlEnd,
        _controller = assetsController ?? DownloadAssetsController(),
        _fs = fileSystem ?? const LocalFileSystem();

  Future init() async {
    await _controller.init(assetDir: "assets-$languageCode");

    try {
      // Now we store the full path to the language
      path = _controller.assetsDir! + pathStart + languageCode + pathEnd;
      debugPrint("Path: $path");
      _dir = _fs.directory(path);

      downloaded = await _controller.assetsDirAlreadyExists();
      // TODO check that in every unexpected behavior the folder gets deleted and downloaded is false
      debugPrint("assets ($languageCode) loaded: $downloaded");
      if (!downloaded) await _download();

      _timestamp = await _getTimestamp();
      _commitsSinceDownload = await _fetchLatestCommits();

      // Read structure/contents.json as our source of truth:
      // Which pages are available, what is the order in the menu
      var structure = jsonDecode(_fs
          .file(join(path, 'structure', 'contents.json'))
          .readAsStringSync());

      for (var element in structure["worksheets"]) {
        // TODO add error handling
        _pageIndex.add(element['page']);
        _pages[element['page']] = Page(element['page'], element['title'],
            element['filename'], element['version']);
      }

      _checkConsistency();

      // Register available images
      await for (var file in _fs
          .directory(join(path, 'files'))
          .list(recursive: false, followLinks: false)) {
        if (file is File) {
          _images[basename(file.path)] = Image(basename(file.path));
        } else {
          debugPrint("Found unexpected element $file in files/ directory");
        }
      }
    } catch (e) {
      String msg = "Error initializing data structure: $e";
      debugPrint(msg);
      // Delete the whole folder (TODO make sure this is called in every unexpected situation)
      downloaded = false;
      _controller.clearAssets();
      throw Exception(msg);
    }
  }

  /// Check whether all files mentioned in structure/contents.json are present
  /// and whether there is no extra file present
  ///
  /// TODO maybe remove this function on startup. Rather implement gracious
  /// error handling if a page we expect to be there can't be loaded because
  /// a HTML file is missing...
  Future<void> _checkConsistency() async {
    Set<String> files = {};
    await for (var file in _dir.list(recursive: false, followLinks: false)) {
      if (file is File) {
        files.add(basename(file.path));
      }
    }
    _pages.forEach((key, page) {
      if (!files.remove(page.fileName)) {
        debugPrint(
            "Warning: Structure mentions ${page.fileName} but the file is missing");
      }
    });
    if (files.isNotEmpty) debugPrint("Warning: Found orphaned files $files");
  }

  Future _download() async {
    debugPrint("Starting downloadLanguage: $languageCode ...");

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
      _controller.clearAssets();
    }
  }

  Future<void> removeResources() async {
    await _controller.clearAssets();
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
      throw Exception(msg);
    }
    debugPrint(timestamp.toString());
    return timestamp;
  }

  /// Returns the timestamp in a human readable string. If we don't have a timestamp, an empty string is returned.
  String formatTimestamp() {
    if (_timestamp == null) return "";
    return DateFormat('yyyy-MM-dd HH:mm').format(_timestamp!);
  }

  /// returns 0 if there was some error
  Future<int> _fetchLatestCommits() async {
    // TODO this should be rewritten a bit: what exactly do we return here?
    if (_timestamp == null) {
      return 0;
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
      debugPrint("Failed to fetch latest commits ${response.statusCode}");
      return 0;
    }
  }

  /// Return the HTML code of the page identified by [index]
  /// If we don't have it already cached in memory, we read it from the file in our local storage.
  /// TODO error handling
  Future<String> getPageContent(String pageName) async {
    Page? page = _pages[pageName];
    if (page == null) {
      debugPrint("Internal error: Couldn't find page $pageName");
      return "";
    }
    if (page.content == null) {
      debugPrint(
          "Fetching content of '$pageName' in language '$languageCode'...");
      page.content = await _fs.file(join(path, page.fileName)).readAsString();

      // Load images directly into the HTML:
      // Replace <img src="xyz.png"> with <img src="base64-encoded image data">
      page.content = page.content!
          .replaceAllMapped(RegExp(r'src="files/([^.]+.png)"'), (match) {
        var image = _images[match.group(1)!];
        if (image == null) {
          debugPrint(
              'Warning: image ${match.group(1)} missing (in ${page.fileName})');
          return match.group(0)!;
        } else if (image.data == null) {
          // Load image data. TODO move this into the Image class?
          image.data = imageToBase64(_fs.file(join(path, 'files', image.name)));
          debugPrint("Successfully loaded ${image.name}");
        }
        return 'src="data:image/png;base64,${image.data}"';
      });
    }
    return page.content!;
  }

  /// Returns an list with all the worksheet titles in the menu.
  /// The list is ordered as identifier -> translated title
  LinkedHashMap<String, String> getPageTitles() {
    LinkedHashMap<String, String> titles = LinkedHashMap<String, String>();
    for (int i = 0; i < _pageIndex.length; i++) {
      titles[_pageIndex[i]] = _pages[_pageIndex[i]]!.title;
    }
    return titles;
  }
}

String imageToBase64(File image) {
  List<int> imageBytes = image.readAsBytesSync();
  return base64Encode(imageBytes);
}
