import 'dart:collection';
import 'dart:convert';
import 'package:download_assets/download_assets.dart';
import 'package:file/local.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:four_training/data/globals.dart';
import 'package:file/file.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;

final fileSystemProvider = Provider<FileSystem>((ref) {
  return const LocalFileSystem();
});

final imageContentProvider = Provider.family<String, String>((ref, imageName) {
  final String langCode = ref.watch(currentLanguageProvider);
  final String path = ref.watch(languageProvider(langCode).notifier).path;
  final fileSystem = ref.watch(fileSystemProvider);
  // TODO add error handling
  String data = imageToBase64(fileSystem.file(join(path, 'files', imageName)));
  debugPrint("Successfully loaded $imageName");
  return data;
});

final pageContentProvider =
    FutureProvider.family<String, String>((ref, pageName) async {
  final fileSystem = ref.watch(fileSystemProvider);
  final langCode = ref.watch(currentLanguageProvider);
  final currentLanguage = ref.watch(languageProvider(langCode));
  Page? page = currentLanguage.pages[pageName];
  if (page == null) {
    debugPrint("Internal error: Couldn't find page $pageName");
    return "";
  }
  debugPrint("Fetching content of '$pageName' in language '$langCode'...");
  String content = await fileSystem
      .file(join(
          ref.watch(languageProvider(langCode).notifier).path, page.fileName))
      .readAsString();

  // Load images directly into the HTML:
  // Replace <img src="xyz.png"> with <img src="base64-encoded image data">
  content =
      content.replaceAllMapped(RegExp(r'src="files/([^.]+.png)"'), (match) {
    String imageData = ref.watch(imageContentProvider(match.group(1)!));
    if (imageData == '') {
      debugPrint('Warning: image ${match.group(1)} missing (in $pageName)');
      return match.group(0)!;
    } else {
      return 'src="data:image/png;base64,$imageData"';
    }
  });
  return content;
});

final languageProvider =
    NotifierProvider.family<LanguageController, Language, String>(() {
  return LanguageController();
});

final currentLanguageProvider = StateProvider<String>((ref) {
  // TODO read from Platform.localeName (see AppLanguage) and persist this to SharedPreferences
  return 'en';
});

/// late members will be initialized after calling init()
class LanguageController extends FamilyNotifier<Language, String> {
  String languageCode = '';
  final DownloadAssetsController _controller;
  final FileSystem _fs;

  /// full local path to directory holding all content
  late final String path;

  /// Directory object of path
  late final Directory _dir;

  /// Did we download all content?
  bool _downloaded = false;
  bool get downloaded => _downloaded;

  DateTime? _timestamp; // TODO
  int _commitsSinceDownload = 0; // TODO

  /// We use dependency injection (optional parameters [assetsController] and
  /// [fileSystem]) so that we can test the class well
  LanguageController(
      {DownloadAssetsController? assetsController, FileSystem? fileSystem})
      : _controller = assetsController ?? DownloadAssetsController(),
        _fs = fileSystem ?? const LocalFileSystem();

  @override
  Language build(String arg) {
    languageCode = arg;
    return Language(arg, {}, [], {}, 0, DateTime(2023, 1, 1));
  }

  Future<int> init() async {
//    final fileSystem = ref.watch(fileSystemProvider);
    await _controller.init(assetDir: "assets-$languageCode");

    try {
      // Now we store the full path to the language
      path = _controller.assetsDir! +
          Globals.pathStart +
          languageCode +
          Globals.pathEnd;
      debugPrint("Path: $path");
      _dir = _fs.directory(path);

      _downloaded = await _controller.assetsDirAlreadyExists();
      // TODO check that in every unexpected behavior the folder gets deleted and downloaded is false
      debugPrint("assets ($languageCode) loaded: $_downloaded");
      if (!_downloaded) await _download();

      // Store the size of the downloaded directory
      int sizeInKB = await _calculateMemoryUsage();

      _timestamp = await _getTimestamp();
      _commitsSinceDownload = await _fetchLatestCommits();

      // Read structure/contents.json as our source of truth:
      // Which pages are available, what is the order in the menu
      var structure = jsonDecode(_fs
          .file(join(path, 'structure', 'contents.json'))
          .readAsStringSync());

      /// Holds our pages identified by their English name (e.g. "Hearing_from_God")
      final Map<String, Page> pages = {};

      /// Define the order of pages in the menu: List of page names
      /// Not all pages must be in the menu, so every item in this list must be
      /// in _pages, but not every item of _pages must be in this list
      final List<String> pageIndex = [];

      final Map<String, Image> images = {};

      for (var element in structure["worksheets"]) {
        // TODO add error handling
        pageIndex.add(element['page']);
        pages[element['page']] = Page(element['page'], element['title'],
            element['filename'], element['version']);
      }

      await _checkConsistency(pages);

      // Register available images
      await for (var file in _fs
          .directory(join(path, 'files'))
          .list(recursive: false, followLinks: false)) {
        if (file is File) {
          images[basename(file.path)] = Image(basename(file.path));
        } else {
          debugPrint("Found unexpected element $file in files/ directory");
        }
      }
      state = Language(
          languageCode, pages, pageIndex, images, sizeInKB, _timestamp!);
      return _commitsSinceDownload;
    } catch (e) {
      String msg = "Error initializing data structure: $e";
      debugPrint(msg);
      // Delete the whole folder (TODO make sure this is called in every unexpected situation)
      _downloaded = false;
      _controller.clearAssets();
      throw Exception(msg);
    }
  }

  Future _download() async {
    debugPrint("Starting downloadLanguage: $languageCode ...");
    String remoteUrl = Globals.urlStart + languageCode + Globals.urlEnd;

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
            _downloaded = true;
          }
        },
      );
    } on DownloadAssetsException catch (e) {
      debugPrint(e.toString());
      _downloaded = false;
      _controller.clearAssets();
    }
  }

  /// Return the total size of all files in our directory in kB
  Future<int> _calculateMemoryUsage() async {
    var files = await _dir.list(recursive: true).toList();
    var sizeInBytes =
        files.fold(0, (int sum, file) => sum + file.statSync().size);
    return (sizeInBytes / 1000).ceil(); // let's never round down
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

  /// returns 0 if there was some error
  Future<int> _fetchLatestCommits() async {
    // TODO this should be rewritten a bit: what exactly do we return here?
    if (_timestamp == null) {
      return 0;
    }
    var t = _timestamp!.subtract(const Duration(
        days: 0)); // TODO just for testing, use timestamp instead
    var uri = Globals.latestCommitsStart +
        languageCode +
        Globals.latestCommitsEnd +
        t.toIso8601String();
    debugPrint(uri);
    final response = await http.get(Uri.parse(uri));

    if (response.statusCode == 200) {
      // = OK response
      var data = json.decode(response.body);
      int commits = data.length;
      debugPrint(
          "Found $commits new commits since download on $t ($languageCode)");
      return commits;
    } else {
      debugPrint("Failed to fetch latest commits ${response.statusCode}");
      return 0;
    }
  }

  /// Check whether all files mentioned in structure/contents.json are present
  /// and whether there is no extra file present
  ///
  /// TODO maybe remove this function on startup. Rather implement gracious
  /// error handling if a page we expect to be there can't be loaded because
  /// a HTML file is missing...
  Future<void> _checkConsistency(final Map<String, Page> pages) async {
    Set<String> files = {};
    await for (var file in _dir.list(recursive: false, followLinks: false)) {
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

  Future<void> removeResources() async {
    _downloaded = false;
    await _controller.clearAssets();
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

  final DateTime timestamp; // TODO
  final int commitsSinceDownload = 0; // TODO

  /// We use dependency injection (optional parameters [assetsController] and
  /// [fileSystem]) so that we can test the class well
  const Language(this.languageCode, this.pages, this.pageIndex, this.images,
      this.sizeInKB, this.timestamp)
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

  /// Returns the timestamp in a human readable string. If we don't have a timestamp, an empty string is returned.
  String formatTimestamp(
      {required String style, required bool adjustToTimeZone}) {
    DateTime tempTimestamp = timestamp;
    if (adjustToTimeZone) {
      DateTime dateTime = DateTime.now();
      Duration offset = dateTime.timeZoneOffset;
      tempTimestamp.add(offset);
    }

    String format = "";
    switch (style) {
      case 'date':
        format = 'yyyy-MM-dd';
        break;
      case 'time':
        format = 'HH:mm';
        break;
      case 'full':
        format = 'yyyy-MM-dd HH:mm';
        break;
      default:
        format = 'yyyy-MM-dd HH:mm';
        break;
    }

    return DateFormat(format).format(tempTimestamp);
  }
}

String imageToBase64(File image) {
  List<int> imageBytes = image.readAsBytesSync();
  return base64Encode(imageBytes);
}
