import 'package:download_assets/download_assets.dart';
import 'package:file/memory.dart';
import 'package:mocktail/mocktail.dart';

/* This are utility functions for the integration test.
   Unfortunately it seems not be easily possible to move this into
   the test/ folder and include it from there in our background_task.dart,
   so that's why it is in our "normal" code directory */

class MockDownloadAssetsController extends Mock
    implements DownloadAssetsController {}

// Simulate that German files are already downloaded
MockDownloadAssetsController createMockDownloadAssetsController() {
  final mock = MockDownloadAssetsController();
  when(() => mock.init(assetDir: any(named: 'assetDir')))
      .thenAnswer((_) async {});
  when(mock.clearAssets).thenAnswer((_) async {});
  when(() => mock.assetsDir).thenReturn('assets-de');
  when(() => mock.assetsDirAlreadyExists()).thenAnswer((_) async => true);
  return mock;
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
