import 'dart:io';

import 'package:app4training/background/background_test.dart';
import 'package:app4training/data/exceptions.dart';
import 'package:app4training/data/globals.dart';
import 'package:dio/dio.dart';
import 'package:download_assets/download_assets.dart';
import 'package:file/chroot.dart';
import 'package:file/local.dart';
import 'package:file/memory.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app4training/data/languages.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;

class MockDownloadAssetsController extends Mock
    implements DownloadAssetsController {}

class FakeDownloadAssetsController extends Fake
    implements DownloadAssetsController {
  late String _assetDir;
  bool initCalled = false;
  bool clearAssetsCalled = false;
  int startDownloadCalls = 0;

  // TODO use this class to test the startDownload() functionality
  @override
  Future init(
      {String assetDir = 'assets', bool useFullDirectoryPath = false}) async {
    _assetDir = assetDir;
    initCalled = true;
    return;
  }

  @override
  String? get assetsDir => _assetDir;

  @override
  Future<bool> assetsDirAlreadyExists() async {
    return false;
  }

  @override
  Future clearAssets() async {
    clearAssetsCalled = true;
  }

  @override
  Future startDownload(
      {required List<String> assetsUrls,
      List<UncompressDelegate> uncompressDelegates = const [UnzipDelegate()],
      Function(double p1)? onProgress,
      Function()? onStartUnziping,
      Function()? onCancel,
      Function()? onDone,
      Map<String, dynamic>? requestQueryParams,
      Map<String, String> requestExtraHeaders = const {}}) async {
    // TODO: implement startDownload
    startDownloadCalls += 1;
    return;
  }
}

class ThrowingDownloadAssetsController extends FakeDownloadAssetsController {
  @override
  Future startDownload(
      {required List<String> assetsUrls,
      List<UncompressDelegate> uncompressDelegates = const [UnzipDelegate()],
      Function(double p1)? onProgress,
      Function()? onStartUnziping,
      Function()? onCancel,
      Function()? onDone,
      Map<String, dynamic>? requestQueryParams,
      Map<String, String> requestExtraHeaders = const {}}) async {
    startDownloadCalls += 1;
    throw DioException(requestOptions: RequestOptions());
  }
}

/// For testing the LanguageController: Simulate essential behavior
/// without needing access to device file system etc.
///
/// By default (downloadLanguages = null), a language is downloaded initially.
/// For other behavior set downloadedLanguages to [] or a set of languages.
class TestLanguageController extends LanguageController {
  final List<String>? _downloadedLanguages;
  final int _languageSize; // size in KB
  final Map<String, Page> _pages; // map of pages that are available
  final bool _initReturns;
  TestLanguageController(
      {List<String>? downloadedLanguages,
      int languageSize = 0,
      Map<String, Page> pages = const {},
      initReturns = false})
      : _downloadedLanguages = downloadedLanguages,
        _languageSize = languageSize,
        _pages = pages,
        _initReturns = initReturns;

  @override
  Language build(String arg) {
    languageCode = arg;
    bool downloaded = true;
    if (_downloadedLanguages != null) {
      downloaded = _downloadedLanguages.contains(arg);
    }
    return Language(downloaded ? arg : '', _pages, const [], const {}, '',
        _languageSize, DateTime.utc(2023));
  }

  @override
  Future<bool> download({bool force = false}) async {
    state = Language(languageCode, _pages, const [], const {}, '',
        _languageSize, DateTime.now().toUtc());
    return true;
  }

  @override
  Future<void> deleteResources() async {
    state =
        Language('', const {}, const [], const {}, '', 0, DateTime.utc(2023));
  }

  @override
  Future<bool> init() async {
    return _initReturns;
  }
}

/// Create a test file system which simulates that the specified languages
/// are downloaded. This is simulated in a very basic way:
/// Only structure/contents.json is existing (with dummy contents)
/// But that's enough for Languages.lazyInit()
Future<MemoryFileSystem> createBasicFileSystem(
    List<String> downloadedLangs) async {
  var fileSystem = MemoryFileSystem();
  for (final lang in downloadedLangs) {
    await fileSystem
        .directory('assets-$lang/html-$lang-main/structure')
        .create(recursive: true);
    String jsonPath = 'assets-$lang/html-$lang-main/structure/contents.json';
    var contentsJson = fileSystem.file(jsonPath);
    await contentsJson.writeAsString('{}');
  }
  return fileSystem;
}

void main() {
  test('Test init() when no files are there', () async {
    var fakeController = FakeDownloadAssetsController();
    final ref = ProviderContainer(overrides: [
      languageProvider.overrideWith(
          () => LanguageController(assetsController: fakeController)),
      fileSystemProvider.overrideWith((ref) => MemoryFileSystem())
    ]);
    final frTest = ref.read(languageProvider('fr').notifier);
    expect(await frTest.init(), false);
    expect(frTest.state.downloaded, false);
    // init() shouldn't start a download
    expect(fakeController.startDownloadCalls, 0);
  });

  test('Test lazyInit() when no files are there', () async {
    var fakeController = FakeDownloadAssetsController();
    final ref = ProviderContainer(overrides: [
      languageProvider.overrideWith(
          () => LanguageController(assetsController: fakeController)),
      fileSystemProvider.overrideWith((ref) => MemoryFileSystem())
    ]);
    final frTest = ref.read(languageProvider('fr').notifier);
    expect(await frTest.lazyInit(), false);
    expect(frTest.state.downloaded, false);
  });

  test('Test that download() starts the download', () async {
    var fakeController = FakeDownloadAssetsController();
    final ref = ProviderContainer(overrides: [
      languageProvider.overrideWith(
          () => LanguageController(assetsController: fakeController)),
      fileSystemProvider.overrideWith((ref) => MemoryFileSystem())
    ]);
    final frTest = ref.read(languageProvider('fr').notifier);

    // as we're mocking, the language won't be available
    expect(await frTest.download(), false);
    // Verify that download got started
    expect(fakeController.initCalled, true);
    expect(fakeController.startDownloadCalls, 2);
    expect(fakeController.clearAssetsCalled, false);
  });

  test('Test failing download', () async {
    var throwingController = ThrowingDownloadAssetsController();
    final ref = ProviderContainer(overrides: [
      languageProvider.overrideWith(
          () => LanguageController(assetsController: throwingController)),
      fileSystemProvider.overrideWith((ref) => MemoryFileSystem())
    ]);
    final frTest = ref.read(languageProvider('fr').notifier);

    expect(await frTest.download(), false);
    // download shouldn't throw (if it would the test would fail)
    expect(throwingController.startDownloadCalls, 1);
    expect(throwingController.clearAssetsCalled, true);
  });

  group('Test correct behavior after downloading', () {
    group('Test error handling of incorrect files / structure', () {
      test('Test error handling when no files can be found at all', () async {
        final ref = ProviderContainer(overrides: [
          languageProvider.overrideWith(() => LanguageController(
              assetsController: createMockDownloadAssetsController())),
          fileSystemProvider.overrideWith((ref) => MemoryFileSystem())
        ]);
        final deTest = ref.read(languageProvider('de').notifier);

        expect(await deTest.init(), false);
        expect(deTest.state.downloaded, false);
      });

      test('Test error handling when structure is inconsistent', () async {
        var fileSystem = MemoryFileSystem();
        await fileSystem
            .directory('assets-de/html-de-main/structure')
            .create(recursive: true);
        var contentsJson =
            fileSystem.file('assets-de/html-de-main/structure/contents.json');
        await contentsJson.writeAsString('invalid');

        final ref = ProviderContainer(overrides: [
          languageProvider.overrideWith(() => LanguageController(
              assetsController: createMockDownloadAssetsController())),
          fileSystemProvider.overrideWith((ref) => fileSystem)
        ]);
        final deTest = ref.read(languageProvider('de').notifier);
        expect(await deTest.init(), false);
        expect(deTest.state.downloaded, false);
      });

      test('A missing files/ dir should be no problem', () async {
        // We construct a file system in memory with structure/contents.json
        // filled correctly but where HTML files and the files/ dir are missing
        var fileSystem = MemoryFileSystem();
        await fileSystem
            .directory('assets-de/html-de-main/structure')
            .create(recursive: true);
        var readFileSystem = ChrootFileSystem(
            const LocalFileSystem(), path.canonicalize('test/'));
        String jsonPath = 'assets-de/html-de-main/structure/contents.json';
        var contentsJson = fileSystem.file(jsonPath);
        await contentsJson
            .writeAsString(await readFileSystem.file(jsonPath).readAsString());

        final ref = ProviderContainer(overrides: [
          languageProvider.overrideWith(() => LanguageController(
              assetsController: createMockDownloadAssetsController())),
          fileSystemProvider.overrideWith((ref) => fileSystem)
        ]);

        // init() should work (even if expected HTML files are missing)
        final deTest = ref.read(languageProvider('de').notifier);
        expect(await deTest.init(), true);
        expect(deTest.state.downloaded, true);
        expect(deTest.state.downloadTimestamp.compareTo(DateTime(2023)),
            greaterThan(0));
      });
    });

    test('Test lazyInit() when language is available', () async {
      // We construct a file system in memory with structure/contents.json
      final fileSystem = await createBasicFileSystem(['de']);
      final ref = ProviderContainer(overrides: [
        languageProvider.overrideWith(() => LanguageController(
            assetsController: createMockDownloadAssetsController())),
        fileSystemProvider.overrideWith((ref) => fileSystem)
      ]);

      expect(await ref.read(languageProvider('de').notifier).lazyInit(), true);
      final deStatus = ref.read(languageProvider('de'));
      expect(deStatus.downloaded, true);
      expect(deStatus.path, equals('assets-de/html-de-main'));
      expect(
          deStatus.downloadTimestamp.compareTo(DateTime(2023)), greaterThan(0));
    });

    test('Test everything with real content from test/assets-de/', () async {
      final ref = ProviderContainer(overrides: [
        languageProvider.overrideWith(() => LanguageController(
            assetsController: createMockDownloadAssetsController())),
        fileSystemProvider.overrideWith((ref) => ChrootFileSystem(
            const LocalFileSystem(), path.canonicalize('test/')))
      ]);

      final deTest = ref.read(languageProvider('de').notifier);
      expect(await deTest.init(), true);

      // Loads Gottes_Geschichte_(fünf_Finger).html
      String content = await ref.read(pageContentProvider(
          (name: "God's_Story_(five_fingers)", langCode: 'de')).future);

      expect(content, startsWith('<h1>Gottes Geschichte'));
      // The link of this image should have been replaced with image content
      expect(content, isNot(contains('src="files/Hand_4.png"')));
      expect(content, contains('src="data:image/png;base64,'));
      // This should still be there as the image file is missing
      expect(content, contains('src="files/Hand_5.png"'));
      // PDF should be available
      expect(deTest.state.pages['Forgiving_Step_by_Step']?.pdfPath,
          equals('assets-de/pdf-de-main/Schritte_der_Vergebung.pdf'));
      // This PDF is missing
      expect(deTest.state.pages['MissingTest']?.pdfPath, isNull);

      // Test Languages.getPageTitles()
      expect(
          deTest.state.getPageTitles().values,
          orderedEquals(const [
            'Gottes Geschichte (fünf Finger)',
            'Schritte der Vergebung',
            'MissingTest'
          ]));
      expect(deTest.state.sizeInKB, 163);
      expect(deTest.state.path, equals('assets-de/html-de-main'));

      // Test some error handling
      try {
        content = await ref.read(
            pageContentProvider((name: 'MissingTest', langCode: 'de')).future);
      } catch (e) {
        expect(e, isA<LanguageCorruptedException>());
        expect((e as LanguageCorruptedException).exception,
            isA<PathNotFoundException>());
      }
      try {
        content = await ref.read(
            pageContentProvider((name: 'Invalid', langCode: 'de')).future);
      } catch (e) {
        expect(e, isA<PageNotFoundException>());
      }
    });
  });

  test('Test diskUsageProvider', () {
    final ref = ProviderContainer(overrides: [
      languageProvider
          .overrideWith(() => TestLanguageController(languageSize: 42)),
    ]);
    expect(ref.read(diskUsageProvider), countAvailableLanguages * 42);
  });

  test('Test countDownloadedLanguagesProvider', () {
    final ref = ProviderContainer(overrides: [
      languageProvider.overrideWith(() =>
          TestLanguageController(downloadedLanguages: ['de', 'fr', 'en'])),
    ]);
    expect(ref.read(countDownloadedLanguagesProvider), 3);
  });
}
