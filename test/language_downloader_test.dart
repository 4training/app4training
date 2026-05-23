import 'dart:typed_data';

import 'package:app4training/data/globals.dart';
import 'package:app4training/data/language_downloader.dart';
import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

/// Create a zip archive in memory with the given files (path -> content).
Uint8List createTestZip(Map<String, String> files) {
  final archive = Archive();
  for (final entry in files.entries) {
    final data = Uint8List.fromList(entry.value.codeUnits);
    archive.addFile(ArchiveFile(entry.key, data.length, data));
  }
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

/// Helper to set up a mock Dio response for a URL returning zip bytes.
void mockDioGet(MockDio dio, String url, Uint8List zipBytes) {
  when(() => dio.get<List<int>>(
        url,
        options: any(named: 'options'),
      )).thenAnswer((_) async => Response(
        data: zipBytes.toList(),
        statusCode: 200,
        requestOptions: RequestOptions(path: url),
      ));
}

void main() {
  late MemoryFileSystem fs;
  late MockDio dio;
  late LanguageDownloaderImpl downloader;
  const root = '/app-docs';

  setUp(() {
    fs = MemoryFileSystem();
    dio = MockDio();
    downloader = LanguageDownloaderImpl(root: root, dio: dio, fileSystem: fs);
  });

  test('pathFor returns deterministic path', () {
    expect(downloader.pathFor('de'), '/app-docs/assets-de');
    expect(downloader.pathFor('en'), '/app-docs/assets-en');
  });

  test('Happy path: both zips download and extract', () async {
    final htmlZip = createTestZip({
      '${Globals.getResourcesDir('de')}/structure/contents.json':
          '{"worksheets":[]}',
      '${Globals.getResourcesDir('de')}/index.html': '<h1>Hello</h1>',
    });
    final pdfZip = createTestZip({
      '${Globals.getPdfDir('de')}/test.pdf': 'pdf-content',
    });

    mockDioGet(dio, Globals.getRemoteUrlHtml('de'), htmlZip);
    mockDioGet(dio, Globals.getRemoteUrlPdf('de'), pdfZip);

    await downloader.download('de');

    expect(await downloader.isDownloaded('de'), true);
    final contentsJson = fs.file(
        '/app-docs/assets-de/${Globals.getResourcesDir('de')}/structure/contents.json');
    expect(await contentsJson.exists(), true);
    expect(await contentsJson.readAsString(), '{"worksheets":[]}');

    final indexHtml = fs.file(
        '/app-docs/assets-de/${Globals.getResourcesDir('de')}/index.html');
    expect(await indexHtml.exists(), true);

    final pdfFile = fs.file(
        '/app-docs/assets-de/${Globals.getPdfDir('de')}/test.pdf');
    expect(await pdfFile.exists(), true);

    // No staging dir left behind
    expect(await fs.directory('/app-docs/assets-de.staging').exists(), false);
  });

  test('Network failure: nothing remains at pathFor and no staging leftover',
      () async {
    // HTML download succeeds but PDF download throws
    final htmlZip = createTestZip({
      '${Globals.getResourcesDir('fr')}/index.html': '<h1>Bonjour</h1>',
    });
    mockDioGet(dio, Globals.getRemoteUrlHtml('fr'), htmlZip);
    when(() => dio.get<List<int>>(
          Globals.getRemoteUrlPdf('fr'),
          options: any(named: 'options'),
        )).thenThrow(DioException(
      requestOptions: RequestOptions(path: Globals.getRemoteUrlPdf('fr')),
    ));

    await expectLater(downloader.download('fr'), throwsA(isA<DioException>()));

    expect(await downloader.isDownloaded('fr'), false);
    expect(await fs.directory('/app-docs/assets-fr.staging').exists(), false);
  });

  test('Corrupted zip: cleanup same as network failure', () async {
    // A zip header (PK\x03\x04) followed by garbage triggers a real decode error
    final corruptedZip = Uint8List.fromList([
      0x50, 0x4B, 0x03, 0x04, // local file header signature
      0xFF, 0xFF, 0xFF, 0xFF, // garbage version/flags
      0xFF, 0xFF, 0xFF, 0xFF, // more garbage
      0xFF, 0xFF, 0xFF, 0xFF,
    ]);
    mockDioGet(dio, Globals.getRemoteUrlHtml('es'), corruptedZip);
    mockDioGet(dio, Globals.getRemoteUrlPdf('es'), corruptedZip);

    await expectLater(downloader.download('es'), throwsA(anything));

    expect(await downloader.isDownloaded('es'), false);
    expect(await fs.directory('/app-docs/assets-es.staging').exists(), false);
  });

  test('Atomic update: failing download preserves prior data', () async {
    // Seed existing data
    final existingDir = fs.directory('/app-docs/assets-it');
    await existingDir.create(recursive: true);
    await fs.file('/app-docs/assets-it/existing.txt').writeAsString('precious');

    // HTML download succeeds but PDF throws — simulates network failure mid-flight
    final htmlZip = createTestZip({
      '${Globals.getResourcesDir('it')}/file.html': '<h1>ciao</h1>',
    });
    mockDioGet(dio, Globals.getRemoteUrlHtml('it'), htmlZip);
    when(() => dio.get<List<int>>(
          Globals.getRemoteUrlPdf('it'),
          options: any(named: 'options'),
        )).thenThrow(DioException(
      requestOptions: RequestOptions(path: Globals.getRemoteUrlPdf('it')),
    ));

    await expectLater(downloader.download('it'), throwsA(isA<DioException>()));

    // Prior data is intact
    expect(await downloader.isDownloaded('it'), true);
    expect(
        await fs.file('/app-docs/assets-it/existing.txt').readAsString(),
        'precious');
  });

  test('Concurrent calls are serialized', () async {
    final callOrder = <String>[];

    final htmlZip1 = createTestZip({
      '${Globals.getResourcesDir('de')}/file.txt': 'de-content',
    });
    final pdfZip1 = createTestZip({
      '${Globals.getPdfDir('de')}/file.pdf': 'de-pdf',
    });
    final htmlZip2 = createTestZip({
      '${Globals.getResourcesDir('fr')}/file.txt': 'fr-content',
    });
    final pdfZip2 = createTestZip({
      '${Globals.getPdfDir('fr')}/file.pdf': 'fr-pdf',
    });

    // Track call ordering via dio mocks
    when(() => dio.get<List<int>>(
          Globals.getRemoteUrlHtml('de'),
          options: any(named: 'options'),
        )).thenAnswer((_) async {
      callOrder.add('de-html-start');
      return Response(
        data: htmlZip1.toList(),
        statusCode: 200,
        requestOptions: RequestOptions(),
      );
    });
    when(() => dio.get<List<int>>(
          Globals.getRemoteUrlPdf('de'),
          options: any(named: 'options'),
        )).thenAnswer((_) async {
      callOrder.add('de-pdf-start');
      return Response(
        data: pdfZip1.toList(),
        statusCode: 200,
        requestOptions: RequestOptions(),
      );
    });
    when(() => dio.get<List<int>>(
          Globals.getRemoteUrlHtml('fr'),
          options: any(named: 'options'),
        )).thenAnswer((_) async {
      callOrder.add('fr-html-start');
      return Response(
        data: htmlZip2.toList(),
        statusCode: 200,
        requestOptions: RequestOptions(),
      );
    });
    when(() => dio.get<List<int>>(
          Globals.getRemoteUrlPdf('fr'),
          options: any(named: 'options'),
        )).thenAnswer((_) async {
      callOrder.add('fr-pdf-start');
      return Response(
        data: pdfZip2.toList(),
        statusCode: 200,
        requestOptions: RequestOptions(),
      );
    });

    // Fire both without awaiting
    final f1 = downloader.download('de');
    final f2 = downloader.download('fr');
    await Future.wait([f1, f2]);

    // de downloads must all complete before fr starts
    final deLastIndex = callOrder.lastIndexOf('de-pdf-start');
    final frFirstIndex = callOrder.indexOf('fr-html-start');
    expect(deLastIndex, lessThan(frFirstIndex));
  });

  test('Crash recovery: pre-seeded staging dir is wiped by next download',
      () async {
    // Simulate crashed prior run leaving a staging dir
    await fs
        .directory('/app-docs/assets-de.staging/leftover')
        .create(recursive: true);
    await fs
        .file('/app-docs/assets-de.staging/leftover/junk.txt')
        .writeAsString('crash-leftover');

    final htmlZip = createTestZip({
      '${Globals.getResourcesDir('de')}/fresh.html': '<h1>Fresh</h1>',
    });
    final pdfZip = createTestZip({
      '${Globals.getPdfDir('de')}/fresh.pdf': 'fresh-pdf',
    });

    mockDioGet(dio, Globals.getRemoteUrlHtml('de'), htmlZip);
    mockDioGet(dio, Globals.getRemoteUrlPdf('de'), pdfZip);

    await downloader.download('de');

    // Old staging leftover is gone
    expect(
        await fs.file('/app-docs/assets-de/leftover/junk.txt').exists(), false);
    // Fresh content is there
    expect(
        await fs
            .file(
                '/app-docs/assets-de/${Globals.getResourcesDir('de')}/fresh.html')
            .exists(),
        true);
  });
}
