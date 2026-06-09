import 'dart:async';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:app4training/data/globals.dart';
import 'package:dio/dio.dart';
import 'package:file/file.dart';
import 'package:path/path.dart' as p;

abstract interface class LanguageDownloader {
  String pathFor(String langCode);
  Future<bool> isDownloaded(String langCode);
  Future<void> download(String langCode);
  Future<void> delete(String langCode);
}

class LanguageDownloaderImpl implements LanguageDownloader {
  final String _root;
  final Dio _dio;
  final FileSystem _fileSystem;
  Completer<void>? _inFlight;

  LanguageDownloaderImpl({
    required String root,
    required Dio dio,
    required FileSystem fileSystem,
  }) : _root = root,
       _dio = dio,
       _fileSystem = fileSystem;

  @override
  String pathFor(String langCode) =>
      p.join(_root, Globals.getAssetsDir(langCode));

  @override
  Future<bool> isDownloaded(String langCode) =>
      _fileSystem.directory(pathFor(langCode)).exists();

  @override
  Future<void> download(String langCode) async {
    // Serialize: wait for any in-flight download to finish
    while (_inFlight != null) {
      await _inFlight!.future;
    }
    final completer = Completer<void>();
    _inFlight = completer;

    final dest = pathFor(langCode);
    final staging = '$dest.staging';
    final old = '$dest.old';

    try {
      // Crash recovery: remove leftover staging dir
      final stagingDir = _fileSystem.directory(staging);
      if (await stagingDir.exists()) {
        await stagingDir.delete(recursive: true);
      }

      // Download both zips concurrently
      final results = await Future.wait([
        _dio.get<List<int>>(
          Globals.getRemoteUrlHtml(langCode),
          options: Options(responseType: ResponseType.bytes),
        ),
        _dio.get<List<int>>(
          Globals.getRemoteUrlPdf(langCode),
          options: Options(responseType: ResponseType.bytes),
        ),
      ]);

      // Extract both zips into staging
      for (final response in results) {
        final bytes = Uint8List.fromList(response.data!);
        final archive = ZipDecoder().decodeBytes(bytes);
        for (final file in archive) {
          final filePath = p.join(staging, file.name);
          if (file.isFile) {
            final outFile = _fileSystem.file(filePath);
            await outFile.parent.create(recursive: true);
            await outFile.writeAsBytes(file.content as List<int>);
          } else {
            await _fileSystem.directory(filePath).create(recursive: true);
          }
        }
      }

      // Atomic swap
      final destDir = _fileSystem.directory(dest);
      final oldDir = _fileSystem.directory(old);

      if (await destDir.exists()) {
        await destDir.rename(old);
      }
      await _fileSystem.directory(staging).rename(dest);

      // Best-effort cleanup of old
      if (await oldDir.exists()) {
        try {
          await oldDir.delete(recursive: true);
        } catch (_) {}
      }
    } catch (e) {
      // Clean up staging on failure
      final stagingDir = _fileSystem.directory(staging);
      if (await stagingDir.exists()) {
        await stagingDir.delete(recursive: true);
      }
      rethrow;
    } finally {
      _inFlight = null;
      completer.complete();
    }
  }

  @override
  Future<void> delete(String langCode) async {
    final dir = _fileSystem.directory(pathFor(langCode));
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
