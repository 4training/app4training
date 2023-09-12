import 'dart:collection';
import 'dart:convert';
import 'package:download_assets/download_assets.dart';
import 'package:file/local.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:four_training/data/globals.dart';
import 'package:file/file.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;

final fileSystemProvider = Provider<FileSystem>((ref) {
  return const LocalFileSystem();
});

/// Unique identifier of an image or a page
typedef Resource = ({String name, String langCode});

/// Provide image data (base64-encoded)
final imageContentProvider = Provider.family<String, Resource>((ref, res) {
  final String path = ref.watch(languageProvider(res.langCode).notifier).path;
  final fileSystem = ref.watch(fileSystemProvider);
  // TODO add error handling
  File image = fileSystem.file(join(path, 'files', res.name));
  debugPrint("Successfully loaded ${res.name}");
  return base64Encode(image.readAsBytesSync());
});

/// Provide HTML content of a specific page in a specific language
final pageContentProvider =
    FutureProvider.family<String, Resource>((ref, page) async {
  final fileSystem = ref.watch(fileSystemProvider);
  final lang = ref.watch(languageProvider(page.langCode));
  Page? pageDetails = lang.pages[page.name];
  if (pageDetails == null) {
    debugPrint(
        "Internal error: Couldn't find page ${page.name}/${page.langCode}");
    return '';
  }

  debugPrint("Fetching content of '${page.name}/${page.langCode}'...");
  String path = ref.watch(languageProvider(page.langCode).notifier).path;
  String content =
      await fileSystem.file(join(path, pageDetails.fileName)).readAsString();

  // Load images directly into the HTML:
  // Replace <img src="xyz.png"> with <img src="base64-encoded image data">
  content =
      content.replaceAllMapped(RegExp(r'src="files/([^.]+.png)"'), (match) {
    if (!lang.images.containsKey(match.group(1))) {
      debugPrint(
          'Warning: image ${match.group(1)} missing (in ${pageDetails.fileName})');
      return match.group(0)!;
    }
    String imageData = ref.watch(
        imageContentProvider((name: match.group(1)!, langCode: page.langCode)));
    return 'src="data:image/png;base64,$imageData"';
  });
  return content;
});

/// Usage:
/// ref.watch(languageProvider('de')) -> get German Language object
/// ref.watch(languageProvider('en').notifier) -> get English LanguageController
final languageProvider =
    NotifierProvider.family<LanguageController, Language, String>(() {
  return LanguageController();
});

/// late members will be initialized after calling init()
class LanguageController extends FamilyNotifier<Language, String> {
  String languageCode = '';
  final DownloadAssetsController _controller;

  /// full local path to directory holding all content
// TODO  late final String path;
  String path = '';

  /// Did we download all content?
  bool _downloaded = false;
  bool get downloaded => _downloaded;

  bool _updatesAvailable = false;
  bool get updatesAvailable => _updatesAvailable;

  /// We use dependency injection (optional parameters [assetsController])
  /// so that we can test the class well
  LanguageController({DownloadAssetsController? assetsController})
      : _controller = assetsController ?? DownloadAssetsController();

  @override
  Language build(String arg) {
    languageCode = arg;
    return Language('', {}, [], {}, 0, DateTime(2023, 1, 1));
  }

  Future<void> init() async {
    final fileSystem = ref.watch(fileSystemProvider);
    await _controller.init(assetDir: "assets-$languageCode");

    try {
      // Now we store the full path to the language
      path = _controller.assetsDir! +
          Globals.pathStart +
          languageCode +
          Globals.pathEnd;
      debugPrint("Path: $path");
      Directory dir = fileSystem.directory(path);

      _downloaded = await _controller.assetsDirAlreadyExists();
      debugPrint("assets ($languageCode) loaded: $_downloaded");
      if (!_downloaded) await _download();
      _downloaded = true;

      // Store the size of the downloaded directory
      int sizeInKB = await _calculateMemoryUsage(dir);

      // Get the timestamp: When were our contents stored on the device?
      FileStat stat =
          await FileStat.stat(join(path, 'structure', 'contents.json'));
      DateTime timestamp = stat.changed; // TODO is this UTC or local time?

      // TODO: Move this somewhere else (See #87)
      if (await _fetchCommitCount(timestamp) > 0) {
        _updatesAvailable = true;
        ref.read(updatesAvailableProvider.notifier).state = true;
      }

      // Read structure/contents.json as our source of truth:
      // Which pages are available, what is the order in the menu
      var structure = jsonDecode(fileSystem
          .file(join(path, 'structure', 'contents.json'))
          .readAsStringSync());

      final Map<String, Page> pages = {};
      final List<String> pageIndex = [];
      final Map<String, Image> images = {};

      for (var element in structure["worksheets"]) {
        // TODO add error handling
        pageIndex.add(element['page']);
        pages[element['page']] = Page(element['page'], element['title'],
            element['filename'], element['version']);
      }
      await _checkConsistency(dir, pages);

      // Register available images
      await for (var file in fileSystem
          .directory(join(path, 'files'))
          .list(recursive: false, followLinks: false)) {
        if (file is File) {
          images[basename(file.path)] = Image(basename(file.path));
        } else {
          debugPrint("Found unexpected element $file in files/ directory");
        }
      }
      state =
          Language(languageCode, pages, pageIndex, images, sizeInKB, timestamp);
    } catch (e) {
      String msg = "Error initializing data structure: $e";
      debugPrint(msg);
      // Delete the whole folder
      _downloaded = false;
      _controller.clearAssets();
      throw Exception(msg);
    }
  }

  // TODO: are there race conditions possible in our LanguageController?
  Future<void> deleteResources() async {
    _downloaded = false;
    await _controller.clearAssets();
    state = Language('', {}, [], {}, 0, DateTime(2023, 1, 1));
  }

  /// Download all files for one language via DownloadAssetsController
  Future _download() async {
    debugPrint("Starting downloadLanguage: $languageCode ...");
    String remoteUrl = Globals.urlStart + languageCode + Globals.urlEnd;

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
        }
      },
    );
  }

  /// Return the total size of all files in our directory in kB
  Future<int> _calculateMemoryUsage(Directory dir) async {
    var files = await dir.list(recursive: true).toList();
    var sizeInBytes =
        files.fold(0, (int sum, file) => sum + file.statSync().size);
    return (sizeInBytes / 1000).ceil(); // let's never round down
  }

  /// Query git html repository whether there are updates available:
  /// How many commits are in our data repository since [since]?
  /// Return values: 0 = no updates available; > 0: updates available; -1: error
  Future<int> _fetchCommitCount(DateTime since) async {
    // since = since.subtract(const Duration(days: 100)); // for testing
    var uri = Globals.latestCommitsStart +
        languageCode +
        Globals.latestCommitsEnd +
        since.toIso8601String();
    debugPrint(uri);
    final response = await http.get(Uri.parse(uri));

    if (response.statusCode == 200) {
      int commits = json.decode(response.body).length;
      debugPrint("Found $commits new commits since $since ($languageCode)");
      return commits;
    } else {
      debugPrint("Failed to fetch latest commits ${response.statusCode}");
      return -1;
    }
  }

  /// Check whether all files mentioned in structure/contents.json are present
  /// and whether there is no extra file present
  ///
  /// TODO maybe remove this function on startup. Rather implement gracious
  /// error handling if a page we expect to be there can't be loaded because
  /// a HTML file is missing...
  Future<void> _checkConsistency(
      Directory dir, final Map<String, Page> pages) async {
    Set<String> files = {};
    await for (var file in dir.list(recursive: false, followLinks: false)) {
      if (file is File) {
        files.add(basename(file.path));
      }
    }
    pages.forEach((key, page) {
      if (!files.remove(page.fileName)) {
        debugPrint(
            "Warning: Structure mentions ${page.fileName} but the file is missing");
      }
    });
    if (files.isNotEmpty) debugPrint("Warning: Found orphaned files $files");
  }
}

/// A page with HTML code: content is loaded on demand
class Page {
  /// English identifier
  final String name;

  /// (translated) Title
  final String title;

  /// (translated) Name of the HTML file
  final String fileName;

  final String version;

  Page(this.name, this.title, this.fileName, this.version);
}

/// Images to be used in pages: content is loaded on demand
class Image {
  final String name;

  Image(this.name);
}

@immutable
class Language {
  final String languageCode;

  /// URL of the zip file to be downloaded
  final String remoteUrl;

  /// The size of the downloaded directory (kB = kilobytes)
  final int sizeInKB;

  /// Holds our pages identified by their English name (e.g. "Hearing_from_God")
  final Map<String, Page> pages;

  /// Define the order of pages in the menu: List of page names
  /// Not all pages must be in the menu, so every item in this list must be
  /// in _pages, but not every item of _pages must be in this list
  final List<String> pageIndex;

  final Map<String, Image> images;

  /// When were the files downloaded on our device? (file system attribute)
  final DateTime downloadTimestamp;

  /// We use dependency injection (optional parameters [assetsController] and
  /// [fileSystem]) so that we can test the class well
  const Language(this.languageCode, this.pages, this.pageIndex, this.images,
      this.sizeInKB, this.downloadTimestamp)
      : remoteUrl = Globals.urlStart + languageCode + Globals.urlEnd;

  /// Returns an list with all the worksheet titles in the menu.
  /// The list is ordered as identifier -> translated title
  LinkedHashMap<String, String> getPageTitles() {
    LinkedHashMap<String, String> titles = LinkedHashMap<String, String>();
    for (int i = 0; i < pageIndex.length; i++) {
      titles[pageIndex[i]] = pages[pageIndex[i]]!.title;
    }
    return titles;
  }
}
