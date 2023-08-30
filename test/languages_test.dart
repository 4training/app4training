import 'package:download_assets/download_assets.dart';
import 'package:file/chroot.dart';
import 'package:file/local.dart';
import 'package:file/memory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:four_training/data/languages.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;

class MockLanguageController extends Mock implements LanguageController {}

class MockDownloadAssetsController extends Mock
    implements DownloadAssetsController {}

class FakeDownloadAssetsController extends Fake
    implements DownloadAssetsController {
  late String _assetDir;
  bool initCalled = false;
  bool startDownloadCalled = false;

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
    return;
  }

  @override
  Future startDownload(
      {required List<String> assetsUrls,
      Function(double p1)? onProgress,
      Function()? onCancel,
      Map<String, dynamic>? requestQueryParams,
      Map<String, String> requestExtraHeaders = const {}}) async {
    // TODO: implement startDownload
    startDownloadCalled = true;
    return;
  }
}

void main() {
  late DownloadAssetsController mock;

  test('Test the download process', () async {
    var fileSystem = MemoryFileSystem();
    var fakeController = FakeDownloadAssetsController();
    final container = ProviderContainer(overrides: [
      languageProvider.overrideWith(
          () => LanguageController(assetsController: fakeController)),
      fileSystemProvider.overrideWith((ref) => fileSystem),
    ]);
    final deTest = container.read(languageProvider('de').notifier);

    // TODO this is not testing very much yet
    try {
      await deTest.init();
      fail('init() should throw because no files are there');
    } catch (e) {
      expect(e, isA<Exception>());
      expect(fakeController.initCalled, true);
      expect(fakeController.startDownloadCalled, true);
    }
  });

  group('Test correct behavior after downloading', () {
    // We assume files are already downloaded, so just mock this
    setUp(() {
      mock = MockDownloadAssetsController();
      when(() => mock.init(assetDir: 'assets-de')).thenAnswer((_) async {
        debugPrint('Successfully called mock.init()');
        return;
      });
      when(mock.clearAssets).thenAnswer((_) async {
        return;
      });
      when(() => mock.assetsDir).thenReturn('assets-de');
      when(() => mock.assetsDirAlreadyExists()).thenAnswer((_) async => true);
    });

    group('Test error handling of incorrect files / structure', () {
      test('Test error handling when no files can be found at all', () async {
        final container = ProviderContainer(overrides: [
          languageProvider
              .overrideWith(() => LanguageController(assetsController: mock)),
          fileSystemProvider.overrideWith((ref) => MemoryFileSystem()),
        ]);
        final deTest = container.read(languageProvider('de').notifier);

        try {
          await deTest.init();
          fail('Test.init() should throw a FileSystemException');
        } catch (e) {
          expect(e.toString(), contains('No such file or directory'));
        }
        expect(deTest.state.downloaded, false);
      });

      test('Test error handling when structure is inconsistent', () async {
        var fileSystem = MemoryFileSystem();
        await fileSystem
            .directory('assets-de/test-html-de-main/structure')
            .create(recursive: true);
        var contentsJson = fileSystem
            .file('assets-de/test-html-de-main/structure/contents.json');
        contentsJson.writeAsString('invalid');
        final container = ProviderContainer(overrides: [
          languageProvider
              .overrideWith(() => LanguageController(assetsController: mock)),
          fileSystemProvider.overrideWith((ref) => fileSystem),
        ]);
        final deTest = container.read(languageProvider('de').notifier);
        try {
          await deTest.init();
          fail('Test.init() should throw while decoding contents.json');
        } catch (e) {
          expect(e.toString(), contains('FormatException'));
        }
        expect(deTest.state.downloaded, false);
      });
    });

    test('Test everything with real content from test/assets-de/', () async {
      var fileSystem =
          ChrootFileSystem(const LocalFileSystem(), path.canonicalize('test/'));
      final container = ProviderContainer(overrides: [
        languageProvider
            .overrideWith(() => LanguageController(assetsController: mock)),
        fileSystemProvider.overrideWith((ref) => fileSystem),
      ]);

      final deTest = container.read(languageProvider('de').notifier);
      await deTest.init();

      // Loads Gottes_Geschichte_(fünf_Finger).html
      String content = await container.read(pageContentProvider(
          (name: "God's_Story_(five_fingers)", langCode: 'de')).future);

      expect(content, startsWith('<h1>Gottes Geschichte'));
      // The link of this image should have been replaced with image content
      expect(content, isNot(contains('src="files/Hand_4.png"')));
      expect(content, contains('src="data:image/png;base64,'));
      // This should still be there as the image file is missing
      expect(content, contains('src="files/Hand_5.png"'));

      // Test Languages.getPageTitles()
      expect(
          deTest.state.getPageTitles().values,
          orderedEquals(const [
            'Gottes Geschichte (fünf Finger)',
            'Schritte der Vergebung'
          ]));
      expect(deTest.state.sizeInKB, 79);
      expect(deTest.state.path, equals('assets-de/test-html-de-main'));
    });
  });
}
