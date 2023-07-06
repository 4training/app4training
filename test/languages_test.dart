import 'package:download_assets/download_assets.dart';
import 'package:file/chroot.dart';
import 'package:file/local.dart';
import 'package:file/memory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:four_training/data/languages.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;

class MockDownloadAssetsController extends Mock
    implements DownloadAssetsController {}

class FakeDownloadAssetsController extends Fake
    implements DownloadAssetsController {
  // TODO use this class to test the startDownload() functionality
  @override
  Future init(
      {String assetDir = 'assets', bool useFullDirectoryPath = false}) async {
    return;
  }

  @override
  String? get assetsDir => "assets-de";

  @override
  Future<bool> assetsDirAlreadyExists() async {
    return true;
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
    return;
  }
}

void main() {
  test('Test whether Language.init() fails in _getTimestamp()', () async {
    // What happens when no files can be found at all...
    var mock = MockDownloadAssetsController();
    when(() => mock.init(assetDir: 'assets-de')).thenAnswer((_) async {
      return;
    });
    when(mock.clearAssets).thenAnswer((_) async {
      return;
    });
    when(() => mock.assetsDir).thenReturn('assets-de');
    when(() => mock.assetsDirAlreadyExists()).thenAnswer((_) async => true);

    var deTest =
        Language('de', assetsController: mock, fileSystem: MemoryFileSystem());
    try {
      await deTest.init();
      fail('Test.init() should throw an exception during _getTimestamp()');
    } catch (e) {
      expect(e.toString(), contains("Error getting timestamp"));
    }
    expect(deTest.downloaded, false);
    expect(deTest.path, equals('assets-de/test-html-de-main'));
  });

  test('Test everything with the files in our test folder', () async {
    // Run tests using the files in test/assets-de/
    var mock = MockDownloadAssetsController();
    when(() => mock.init(assetDir: 'assets-de')).thenAnswer((_) async {
      return;
    });
    when(mock.clearAssets).thenAnswer((_) async {
      return;
    });
    when(() => mock.assetsDir).thenReturn('assets-de');
    when(() => mock.assetsDirAlreadyExists()).thenAnswer((_) async => true);

    var fileSystem =
        ChrootFileSystem(const LocalFileSystem(), path.canonicalize('test/'));
    var deTest = Language('de', assetsController: mock, fileSystem: fileSystem);
    await deTest.init();
    String content = await deTest.getPageContent(0);
    expect(content, isNotEmpty);

    // TODO write more tests
  });

  test('Check with fake', () async {
    // TODO: test something meaningful
    var mockedController = FakeDownloadAssetsController();
    var deTest = Language('de', assetsController: mockedController);
    try {
      await deTest.init();
    } catch (e) {
      expect(e, isA<Exception>());
    }
  });
}
