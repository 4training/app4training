import 'dart:async';
import 'dart:collection';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:app4training/data/globals.dart';
import 'package:app4training/features/perf/perf_logger.dart';
import 'package:dio/dio.dart';
import 'package:file/file.dart';
import 'package:path/path.dart' as p;

/// One entry of a decoded zip archive: a file together with its contents,
/// or - when [bytes] is null - a directory that has to exist even if it
/// ends up empty (e.g. the files/ dir of a language without images).
typedef ArchiveEntry = ({String path, Uint8List? bytes});

/// Decodes a zip archive into a flat list of [ArchiveEntry]s
typedef ZipDecoderFn = Future<List<ArchiveEntry>> Function(Uint8List zipBytes);

/// How many zip archives may be decoded at the same time.
///
/// Onboarding downloads up to kMaxParallelLanguageDownloads languages at
/// once, each of them with an HTML and a PDF archive. Decoding all of those
/// simultaneously would hold several decompressed archives in memory at the
/// same time - too much to ask of a 4 GB device.
const int kMaxParallelZipDecodes = 2;

final _zipDecodeLimit = _Semaphore(kMaxParallelZipDecodes);

/// Decode a zip archive. This is pure, synchronous CPU work: on a slow
/// device it takes seconds per archive, which is why [decodeZipInIsolate]
/// (the default of [LanguageDownloaderImpl]) keeps it away from the UI.
List<ArchiveEntry> decodeZipEntries(Uint8List zipBytes) {
  final archive = ZipDecoder().decodeBytes(zipBytes);
  return [
    for (final file in archive)
      (path: file.name, bytes: file.isFile ? file.content : null)
  ];
}

/// Run [decodeZipEntries] in a short-lived worker isolate, so that
/// downloading a language doesn't freeze every frame while it is unpacked.
///
/// The decoded contents are copied back to this isolate (instead of being
/// written to disk inside the worker) so that all file access keeps going
/// through the injected [FileSystem] and stays testable. Copying a few MB
/// is negligible next to the decoding itself.
Future<List<ArchiveEntry>> decodeZipInIsolate(Uint8List zipBytes) =>
    Isolate.run(() => decodeZipEntries(zipBytes));

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
  final ZipDecoderFn _decodeZip;
  final Map<String, Completer<void>> _inFlightByLang = {};

  LanguageDownloaderImpl({
    required String root,
    required Dio dio,
    required FileSystem fileSystem,
    ZipDecoderFn? zipDecoder,
  }) : _root = root,
       _dio = dio,
       _fileSystem = fileSystem,
       _decodeZip = zipDecoder ?? decodeZipInIsolate;

  @override
  String pathFor(String langCode) =>
      p.join(_root, Globals.getAssetsDir(langCode));

  @override
  Future<bool> isDownloaded(String langCode) =>
      _fileSystem.directory(pathFor(langCode)).exists();

  @override
  Future<void> download(String langCode) async {
    // Serialize per language; different languages may download in parallel
    while (_inFlightByLang.containsKey(langCode)) {
      await _inFlightByLang[langCode]!.future;
    }
    final completer = Completer<void>();
    _inFlightByLang[langCode] = completer;

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
      final results = await PerfLogger.span(
          'download.fetchZips',
          () => Future.wait([
                _dio.get<List<int>>(
                  Globals.getRemoteUrlHtml(langCode),
                  options: Options(responseType: ResponseType.bytes),
                ),
                _dio.get<List<int>>(
                  Globals.getRemoteUrlPdf(langCode),
                  options: Options(responseType: ResponseType.bytes),
                ),
              ]));

      // Extract both zips into staging
      for (final response in results) {
        await _extractInto(staging, response.data!);
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
      _inFlightByLang.remove(langCode);
      completer.complete();
    }
  }

  /// Unpack the zip archive in [zipData] into the [staging] directory
  Future<void> _extractInto(String staging, List<int> zipData) async {
    // dio hands us a Uint8List already - don't pay for a second copy of a
    // multi-megabyte buffer just to satisfy the type
    final bytes = zipData is Uint8List ? zipData : Uint8List.fromList(zipData);
    // The span includes time spent queueing for a decode slot - on a slow
    // device that wait is part of what the user experiences
    final entries = await PerfLogger.span('download.decodeZip',
        () => _zipDecodeLimit.run(() => _decodeZip(bytes)),
        data: () => {'zipBytes': bytes.length});

    await PerfLogger.span('download.writeFiles', () async {
      // An archive holds hundreds of files in a handful of directories, so
      // remember which ones we created instead of asking for each file again
      final createdDirs = <String>{};
      for (final entry in entries) {
        final entryPath = p.join(staging, entry.path);
        final bytes = entry.bytes;
        if (bytes == null) {
          if (createdDirs.add(entryPath)) {
            await _fileSystem.directory(entryPath).create(recursive: true);
          }
          continue;
        }
        final outFile = _fileSystem.file(entryPath);
        if (createdDirs.add(outFile.parent.path)) {
          await outFile.parent.create(recursive: true);
        }
        await outFile.writeAsBytes(bytes);
      }
    }, data: () => {'files': entries.length});
  }

  @override
  Future<void> delete(String langCode) async {
    final dir = _fileSystem.directory(pathFor(langCode));
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}

/// Lets at most [_permits] operations run at the same time; the rest queue up
class _Semaphore {
  _Semaphore(this._permits);

  int _permits;
  final Queue<Completer<void>> _waiting = Queue<Completer<void>>();

  Future<T> run<T>(Future<T> Function() action) async {
    if (_permits > 0) {
      _permits--;
    } else {
      final completer = Completer<void>();
      _waiting.add(completer);
      await completer.future; // the permit is handed over to us directly
    }
    try {
      return await action();
    } finally {
      if (_waiting.isEmpty) {
        _permits++;
      } else {
        _waiting.removeFirst().complete();
      }
    }
  }
}
