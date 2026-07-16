import 'dart:convert';

import 'package:app4training/data/connectivity_service.dart';
import 'package:app4training/data/globals.dart';
import 'package:app4training/data/language_downloader.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;

/* These are utility functions for the integration test.
   Unfortunately it seems not be easily possible to move this into
   the test/ folder and include it from there in our background_task.dart,
   so that's why it is in our "normal" code directory */

/// A test double for [LanguageDownloader] backed by a [FileSystem].
/// [download] records calls in [downloadCalls] but does not write files —
/// pre-seed the file system if a test needs a language to appear downloaded.
class FakeLanguageDownloader implements LanguageDownloader {
  final FileSystem fileSystem;
  final String root;
  final bool throwOnDownload;
  int downloadCalls = 0;
  int deleteCalls = 0;

  /// The language codes passed to [download], in call order.
  final List<String> downloadedLangs = [];

  FakeLanguageDownloader({
    required this.fileSystem,
    this.root = '',
    this.throwOnDownload = false,
  });

  @override
  String pathFor(String langCode) =>
      p.join(root, Globals.getAssetsDir(langCode));

  @override
  Future<bool> isDownloaded(String langCode) =>
      fileSystem.directory(pathFor(langCode)).exists();

  @override
  Future<void> download(String langCode) async {
    downloadCalls += 1;
    downloadedLangs.add(langCode);
    if (throwOnDownload) {
      throw Exception('Simulated download failure');
    }
  }

  @override
  Future<void> delete(String langCode) async {
    deleteCalls += 1;
    final dir = fileSystem.directory(pathFor(langCode));
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}

/// A test double for [ConnectivityService] with a controllable result.
/// Set [unmetered] to simulate being on WiFi/ethernet (true) or mobile (false).
/// Lives in `lib/` so the background isolate's integration test can import it
/// too (same rationale as [FakeLanguageDownloader]).
class FakeConnectivityService implements ConnectivityService {
  bool unmetered;
  int isUnmeteredCalls = 0;

  FakeConnectivityService({this.unmetered = false});

  @override
  Future<bool> isUnmetered() async {
    isUnmeteredCalls += 1;
    return unmetered;
  }
}

/// A fake HTTP client for the background isolate's integration test.
/// Always returns an empty commit list (HTTP 200), so
/// [LanguageStatusNotifier.check] persists a fresh lastChecked timestamp
/// without hitting the live GitHub API (which is rate-limited and makes the
/// test flaky). An empty list keeps updatesAvailable false, so the background
/// download phase stays a no-op.
Client fakeNoUpdatesClient() {
  return MockClient((request) async => Response(json.encode([]), 200));
}

// Simulate a file system where German is downloaded with one worksheet
Future<MemoryFileSystem> createTestFileSystem() async {
  var fileSystem = MemoryFileSystem();
  await fileSystem
      .directory('assets-de/html-de-main/structure')
      .create(recursive: true);
  await fileSystem
      .file('assets-de/html-de-main/structure/contents.json')
      .writeAsString('''
{
    "language_code": "de",
    "english_name": "German",
    "worksheets": [
        {
            "page": "Forgiving_Step_by_Step",
            "title": "Schritte der Vergebung",
            "filename": "Schritte_der_Vergebung.html",
            "version": "1.3",
            "pdf": "Schritte_der_Vergebung.pdf"
        }
    ]
}
''');
  await fileSystem.directory('assets-de/html-de-main/files').create();
  await fileSystem
      .file('assets-de/html-de-main/Schritte_der_Vergebung.html')
      .writeAsString('<h1>Schritte der Vergebung</h1>');
  return fileSystem;
}
