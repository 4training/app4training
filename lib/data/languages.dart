import 'dart:collection';
import 'dart:convert';
import 'package:app4training/data/exceptions.dart';
import 'package:app4training/features/perf/perf_logger.dart';
import 'package:file/local.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app4training/data/globals.dart';
import 'package:file/file.dart';
import 'package:path/path.dart';
// ignore: implementation_imports, invalid_use_of_internal_member
import 'package:riverpod/src/framework.dart' show $RefArg;

/// File system access as a provider to enable better testing
final fileSystemProvider = Provider<FileSystem>((ref) {
  return const LocalFileSystem();
});

/// Unique identifier of an image or a page
typedef Resource = ({String name, String langCode});

/// Which images does a page reference? <img src="files/xyz.png">
final _imageReference = RegExp(r'src="files/([^.]+.png)"');

/// Provide image data (base64-encoded)
/// Returns empty string in case something went wrong
final imageContentProvider = FutureProvider.family<String, Resource>((
  ref,
  res,
) async {
  final String path = ref.watch(languageProvider(res.langCode)).path;
  if (path == '') {
    debugPrint(
      "Error: Can't load image ${res.name} in language ${res.langCode}",
    );
    return '';
  }
  final fileSystem = ref.watch(fileSystemProvider);
  try {
    File image = fileSystem.file(join(path, 'files', res.name));
    if (kDebugMode) debugPrint('Successfully loaded ${res.name}');
    return base64Encode(await image.readAsBytes());
  } on FileSystemException catch (e) {
    debugPrint("Couldn't load ${res.name}: $e");
    return '';
  }
}, retry: null);

/// Provide HTML content of a specific page in a specific language
/// throws [LanguageNotDownloadedException]: just download the language again
/// throws [PageNotFoundException]: Hm, errorneous link?
/// throws [LanguageCorruptedException]: oops,
/// hope this goes away by deleting + re-downloading the language
final pageContentProvider = FutureProvider.family<String, Resource>((
  ref,
  page,
) async {
  final fileSystem = ref.watch(fileSystemProvider);
  final lang = ref.watch(languageProvider(page.langCode));
  if (!lang.downloaded) {
    throw LanguageNotDownloadedException(page.langCode);
  }
  Page? pageDetails = lang.pages[page.name];
  if (pageDetails == null) {
    throw PageNotFoundException(page.name, page.langCode);
  }
  if (lang.path == '') {
    throw LanguageCorruptedException(page.langCode, 'Empty path');
  }

  debugPrint("Fetching content of '${page.name}/${page.langCode}'...");
  int htmlBytes = 0, imageCount = 0;
  return PerfLogger.span('page.loadContent', () async {
    try {
      String content =
          await fileSystem
              .file(join(lang.path, pageDetails.fileName))
              .readAsString();
      htmlBytes = content.length;

      // Read and encode all images of this page at once: doing that one by
      // one while building the HTML string meant a series of blocking disk
      // reads right before the first frame of a page could be painted.
      final Map<String, String> imageData = {};
      await Future.wait(
        _imageReference
            .allMatches(content)
            .map((match) => match.group(1)!)
            .where(lang.images.containsKey)
            .toSet()
            .map((name) async {
              imageData[name] = await ref.watch(
                imageContentProvider((
                  name: name,
                  langCode: page.langCode,
                )).future,
              );
            }),
      );
      imageCount = imageData.length;

      // Load images directly into the HTML:
      // Replace <img src="xyz.png"> with <img src="base64-encoded image data">
      return content.replaceAllMapped(_imageReference, (match) {
        final String name = match.group(1)!;
        if (!imageData.containsKey(name)) {
          debugPrint(
            'Warning: image $name missing (in ${pageDetails.fileName})',
          );
          return match.group(0)!;
        }
        return 'src="data:image/png;base64,${imageData[name]}"';
      });
    } on FileSystemException catch (e) {
      throw LanguageCorruptedException(
        page.langCode,
        'Error while reading from local storage.',
        e,
      );
    }
  }, data: () => {'htmlBytes': htmlBytes, 'images': imageCount});
}, retry: null);

/// Usage:
/// ref.watch(languageProvider('de')) -> get German Language object
/// ref.watch(languageProvider('en').notifier) -> get English LanguageController
final languageProvider =
    NotifierProvider.family<LanguageController, Language, String>((arg) {
      return LanguageController();
    });

/// How many languages do we have available offline?
final countDownloadedLanguagesProvider = Provider<int>((ref) {
  int countDownloadedLanguages = 0;
  for (String languageCode in ref.watch(availableLanguagesProvider)) {
    if (ref.watch(languageProvider(languageCode)).downloaded) {
      countDownloadedLanguages++;
    }
  }
  return countDownloadedLanguages;
});

class LanguageController extends Notifier<Language> {
  @protected
  String languageCode = '';

  LanguageController();

  @override
  Language build() {
    // In v3, the family arg is accessed via ref.$arg (set by the provider
    // system). This is needed for overrideWith() where the arg isn't passed
    // through the constructor.
    languageCode = ref.$arg as String;
    return Language('', const {}, const [], const {}, '', DateTime.utc(2023));
  }

  /// Download this language and make it available.
  /// Returns whether everything went well
  Future<bool> download() async {
    if (!await _download()) return false;
    return await _load();
  }

  /// Is this language downloaded to the device? If yes, load it into memory.
  /// Returns true when the language is now available, false if not
  Future<bool> init() async {
    // The span records how big the language is, but not which one (no PII)
    return await PerfLogger.span(
      'language.load',
      _load,
      data: () => {'pages': state.pages.length, 'images': state.images.length},
    );
  }

  /// Checks whether the language is downloaded to device but doesn't
  /// load any details into memory.
  /// Returns true when the language is now available, false if not
  Future<bool> lazyInit() async {
    final downloader = ref.read(languageDownloaderProvider);
    String path = join(
      downloader.pathFor(languageCode),
      Globals.getResourcesDir(languageCode),
    );
    final stat = await ref
        .watch(fileSystemProvider)
        .stat(join(path, 'structure', 'contents.json'));
    bool downloaded = (stat.type != FileSystemEntityType.notFound);
    if (kDebugMode) {
      debugPrint(
        "QuickInit trying to load '$languageCode', downloaded: $downloaded",
      );
    }
    if (downloaded) {
      DateTime timestamp = stat.modified.toUtc(); // Always store UTC internally

      state = Language(
        languageCode,
        const {},
        const [],
        const {},
        path,
        timestamp,
      );
      return true;
    }
    return false;
  }

  /// Load our Language structure from the file system resources.
  /// Returns whether everything went well and the language is available now.
  /// This method shouldn't throw
  ///
  /// Everything in here must stay asynchronous and cheap: this runs for every
  /// language at every cold start, on the UI isolate. Deliberately *not* done
  /// here: computing the disk usage (see [languageSizeProvider]) and, outside
  /// of debug builds, the consistency check.
  Future<bool> _load() async {
    final downloader = ref.read(languageDownloaderProvider);
    final fileSystem = ref.watch(fileSystemProvider);

    try {
      // Now we store the full path to the language
      String path = join(
        downloader.pathFor(languageCode),
        Globals.getResourcesDir(languageCode),
      );

      // One stat() answers both questions we have about contents.json:
      // is the language on the device at all, and when was it stored there?
      FileStat stat = await fileSystem.stat(
        join(path, 'structure', 'contents.json'),
      );
      bool downloaded = (stat.type != FileSystemEntityType.notFound);
      if (kDebugMode) {
        debugPrint(
          "Trying to load '$languageCode' from $path,"
          " downloaded: $downloaded",
        );
      }
      if (!downloaded) return false;
      DateTime timestamp = stat.modified.toUtc(); // Always store UTC internally

      // Read structure/contents.json as our source of truth:
      // Which pages are available, what is the order in the menu
      var structure = jsonDecode(
        await fileSystem
            .file(join(path, 'structure', 'contents.json'))
            .readAsString(),
      );

      final Map<String, Page> pages = {};
      final List<String> pageIndex = [];
      final Map<String, Image> images = {};
      final Set<String> pdfFiles = {};

      // Go through existing PDF files
      var pdfPath = join(
        downloader.pathFor(languageCode),
        Globals.getPdfDir(languageCode),
      );
      var pdfDir = fileSystem.directory(pdfPath);
      if (await pdfDir.exists()) {
        await for (var file in pdfDir.list(
          recursive: false,
          followLinks: false,
        )) {
          if (file is File) {
            pdfFiles.add(file.basename);
          } else {
            debugPrint('Found unexpected element $file in the PDF directory');
          }
        }
      }

      // Store everything in our data structures
      for (var element in structure['worksheets']) {
        // TODO add error handling
        pageIndex.add(element['page']);
        String? pdfName; // Stores PDF file name (full path) if it is available
        if (element.containsKey('pdf') && pdfFiles.contains(element['pdf'])) {
          pdfName = join(pdfPath, element['pdf']);
          pdfFiles.remove(element['pdf']);
        }
        pages[element['page']] = Page(
          element['page'],
          element['title'],
          element['filename'],
          element['version'],
          pdfName,
        );
      }

      // Consistency checking...
      if (pdfFiles.isNotEmpty) {
        debugPrint('Found unexpected PDF file(s): $pdfFiles');
      }
      if (kDebugMode) {
        await _checkConsistency(fileSystem.directory(path), pages);
      }

      // Register available images
      var filesDir = fileSystem.directory(join(path, 'files'));
      if (await filesDir.exists()) {
        await for (var file in filesDir.list(
          recursive: false,
          followLinks: false,
        )) {
          if (file is File) {
            images[file.basename] = Image(file.basename);
          } else {
            debugPrint('Found unexpected element $file in files/ directory');
          }
        }
      }
      state = Language(languageCode, pages, pageIndex, images, path, timestamp);
      return true;
    } catch (e) {
      String msg = 'Error initializing data structure: $e';
      debugPrint(msg);
      // Delete the whole folder
      await downloader.delete(languageCode);
      state = Language(
        '',
        const {},
        const [],
        const {},
        '',
        DateTime.utc(2023),
      );
      return false;
    }
  }

  /// Delete this language from the device.
  Future<void> deleteResources() async {
    await ref.read(languageDownloaderProvider).delete(languageCode);
    state = Language('', const {}, const [], const {}, '', DateTime.utc(2023));
  }

  /// Download all files for one language via [LanguageDownloader]
  /// Returns whether we were successful. Shouldn't throw
  Future<bool> _download() async {
    debugPrint("Starting to download language '$languageCode' ...");
    try {
      await ref.read(languageDownloaderProvider).download(languageCode);
    } catch (e) {
      debugPrint("Error while downloading language '$languageCode': $e");
      return false;
    }
    debugPrint("Downloading language '$languageCode' finished.");
    return true;
  }

  /// Check whether all files mentioned in structure/contents.json are present
  /// and whether there is no extra file present
  ///
  /// TODO maybe remove this function on startup. Rather implement gracious
  /// error handling if a page we expect to be there can't be loaded because
  /// a HTML file is missing...
  Future<void> _checkConsistency(
    Directory dir,
    final Map<String, Page> pages,
  ) async {
    Set<String> files = {};
    await for (var file in dir.list(recursive: false, followLinks: false)) {
      if (file is File) {
        files.add(file.basename);
      }
    }
    pages.forEach((key, page) {
      if (!files.remove(page.fileName)) {
        debugPrint(
          "Warning: Structure mentions ${page.fileName} but the file is missing",
        );
      }
    });
    if (files.isNotEmpty) debugPrint("Warning: Found orphaned files $files");
  }
}

/// Holds properties of a page.
/// HTML content is loaded on demand via the pageContentProvider
@immutable
class Page {
  /// English identifier
  final String name;

  /// (translated) Title
  final String title;

  /// (translated) Name of the HTML file
  final String fileName;

  final String version;

  /// Full path of the associated PDF file if it exists on the device
  final String? pdfPath;

  const Page(this.name, this.title, this.fileName, this.version, this.pdfPath);
}

/// Holds properties of an image.
/// Content is loaded on demand via the imageContentProvider
@immutable
class Image {
  final String name;

  const Image(this.name);
}

@immutable
class Language {
  final String languageCode;

  /// Check this getter to see if we have any meaningful data
  bool get downloaded => languageCode != '';

  /// Holds our pages identified by their English name (e.g. "Hearing_from_God")
  final Map<String, Page> pages;

  /// Define the order of pages in the menu: List of page names
  /// Not all pages must be in the menu, so every item in this list must be
  /// in pages, but not every item of pages must be in this list
  final List<String> pageIndex;

  final Map<String, Image> images;

  /// local path to the directory holding all content
  final String path;

  /// When were the files downloaded on our device? file system attribute, UTC
  final DateTime downloadTimestamp;

  const Language(
    this.languageCode,
    this.pages,
    this.pageIndex,
    this.images,
    this.path,
    this.downloadTimestamp,
  );

  /// Returns an list with all the worksheet titles in the menu.
  /// The list is ordered as identifier -> translated title
  LinkedHashMap<String, String> getPageTitles() {
    LinkedHashMap<String, String> titles = LinkedHashMap<String, String>();
    for (int i = 0; i < pageIndex.length; i++) {
      titles[pageIndex[i]] = pages[pageIndex[i]]!.title;
    }
    return titles;
  }

  @override
  String toString() {
    return 'Language $languageCode. Downloaded: $downloaded'
        ' ($downloadTimestamp), local path: $path,'
        ' #pages: ${pages.length}, #images: ${images.length}';
  }
}

/// Provide the disk usage of one language (in kB)
///
/// This is computed on demand and not while loading a language: it means
/// walking the whole language directory and statting every single file
/// (HTML worksheets, images and PDFs alike), which is far too expensive to
/// do for every language at every cold start. Only the settings page needs it.
final languageSizeProvider = FutureProvider.family<int, String>((
  ref,
  langCode,
) async {
  if (!ref.watch(languageProvider(langCode)).downloaded) return 0;
  final downloader = ref.watch(languageDownloaderProvider);
  final dir = ref
      .watch(fileSystemProvider)
      .directory(downloader.pathFor(langCode));
  return calculateMemoryUsage(dir);
});

/// Provide combined disk usage of all languages (in kB)
final diskUsageProvider = FutureProvider<int>((ref) async {
  final List<int> sizes = await Future.wait(<Future<int>>[
    for (String langCode in ref.watch(availableLanguagesProvider))
      ref.watch(languageSizeProvider(langCode).future),
  ]);
  return sizes.fold<int>(0, (int sum, int size) => sum + size);
});

/// Return the total size of all files below [dir] in kB
///
/// Uses the asynchronous stat() so the hundreds of syscalls this needs are
/// handled by the IO thread pool instead of blocking the UI isolate.
Future<int> calculateMemoryUsage(Directory dir) async {
  if (!await dir.exists()) return 0;
  final entities = await dir.list(recursive: true, followLinks: false).toList();
  final stats = await Future.wait(
    entities.whereType<File>().map((file) => file.stat()),
  );
  final sizeInBytes = stats.fold(0, (int sum, FileStat s) => sum + s.size);
  return (sizeInBytes / 1000).ceil(); // let's never round down
}
