import 'dart:convert';
import 'dart:io' show gzip;

import 'package:app4training/features/perf/perf_logger.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';

const String perfDir = '/perf_sessions';

/// Start the PerfLogger on a MemoryFileSystem with a fixed clock
FileSystem startLogger({DateTime? now}) {
  final fileSystem = MemoryFileSystem();
  PerfLogger.enabled = true;
  PerfLogger.markAppStart();
  PerfLogger.start(
    fileSystem: fileSystem,
    directory: perfDir,
    now: () => now ?? DateTime(2026, 8, 27, 14, 30, 5),
    rssBytes: () => 42 * 1024 * 1024,
    autoFlush: false,
  );
  return fileSystem;
}

Future<List<Map<String, dynamic>>> readRecords(FileSystem fileSystem) async {
  final dir = fileSystem.directory(perfDir);
  final files = await dir.list().toList();
  final sessionFile = files.whereType<File>().single;
  final lines = await sessionFile.readAsLines();
  return [for (final line in lines) jsonDecode(line) as Map<String, dynamic>];
}

void main() {
  tearDown(PerfLogger.reset);

  test('records header, spans and events as JSON lines', () async {
    final fileSystem = startLogger();

    final result = await PerfLogger.span(
      'test.async',
      () async => 42,
      data: () => {'extra': 'value'},
    );
    expect(result, 42);
    expect(PerfLogger.spanSync('test.sync', () => 'ok'), 'ok');
    PerfLogger.event('test.event', data: {'count': 3});
    await PerfLogger.flush();

    final records = await readRecords(fileSystem);
    expect(records, hasLength(4));

    expect(records[0]['t'], 'header');
    expect(records[0]['session'], startsWith('2026-08-27_14-30-05'));
    expect(records[0]['buildMode'], 'debug');

    expect(records[1]['t'], 'span');
    expect(records[1]['name'], 'test.async');
    expect(records[1]['durUs'], isA<int>());
    expect(records[1]['startUs'], isA<int>());
    expect(records[1]['rssMB'], 42);
    expect(records[1]['extra'], 'value');
    expect(records[1].containsKey('error'), false);

    expect(records[2]['name'], 'test.sync');

    expect(records[3]['t'], 'event');
    expect(records[3]['name'], 'test.event');
    expect(records[3]['count'], 3);
    expect(records[3]['atUs'], isA<int>());
  });

  test('a failing span rethrows and is recorded with error: true', () async {
    final fileSystem = startLogger();

    await expectLater(
      PerfLogger.span<void>(
        'test.failing',
        () async => throw StateError('boom'),
      ),
      throwsStateError,
    );
    await PerfLogger.flush();

    final records = await readRecords(fileSystem);
    final span = records.singleWhere((r) => r['t'] == 'span');
    expect(span['name'], 'test.failing');
    expect(span['error'], true);
  });

  test('does nothing when disabled', () async {
    final fileSystem = MemoryFileSystem();
    PerfLogger.enabled = false;
    PerfLogger.start(
      fileSystem: fileSystem,
      directory: perfDir,
      autoFlush: false,
    );

    expect(await PerfLogger.span('test', () async => 1), 1);
    PerfLogger.event('test');
    await PerfLogger.flush();

    expect(await fileSystem.directory(perfDir).exists(), false);
    expect(await PerfLogger.countStoredSessions(), 0);
    expect(await PerfLogger.exportAll(), null);
  });

  test('prune keeps the newest sessions plus the current one', () async {
    final fileSystem = startLogger();
    final dir = fileSystem.directory(perfDir);
    await dir.create(recursive: true);
    // 25 older sessions (names sort chronologically)
    for (int i = 0; i < 25; i++) {
      await dir
          .childFile(
            'session-2026-08-01_10-00-${i.toString().padLeft(2, '0')}-000.jsonl',
          )
          .writeAsString('{"t":"header"}\n');
    }

    await PerfLogger.prune();
    await PerfLogger.flush(); // now the current session file exists too

    expect(await PerfLogger.countStoredSessions(), kMaxStoredPerfSessions);
    // The oldest ones got deleted
    expect(
      await dir.childFile('session-2026-08-01_10-00-00-000.jsonl').exists(),
      false,
    );
    // The newest old one survived
    expect(
      await dir.childFile('session-2026-08-01_10-00-24-000.jsonl').exists(),
      true,
    );
  });

  test('exportAll concatenates all sessions into one gzipped file', () async {
    final fileSystem = startLogger();
    final dir = fileSystem.directory(perfDir);
    await dir.create(recursive: true);
    await dir
        .childFile('session-2026-08-01_10-00-00-000.jsonl')
        .writeAsString('{"t":"header","session":"old"}\n');
    // A leftover export from last time must not end up in the new export
    await dir.childDirectory('export').create();
    await dir
        .childDirectory('export')
        .childFile('app4training-perf-old.jsonl.gz')
        .writeAsString('stale');
    PerfLogger.event('fresh');

    final path = await PerfLogger.exportAll();

    expect(path, isNotNull);
    expect(path, endsWith('.jsonl.gz'));
    expect(path, contains('app4training-perf-2026-08-27_14-30-05'));
    final content = utf8.decode(
      gzip.decode(await fileSystem.file(path!).readAsBytes()),
    );
    final lines = content.trim().split('\n');
    expect(lines.first, '{"t":"header","session":"old"}');
    expect(lines.any((l) => l.contains('"fresh"')), true);
    // Only the fresh export remains in the export dir
    expect(await dir.childDirectory('export').list().length, 1);
  });

  test('exportAll flushes and exports the current session', () async {
    final fileSystem = startLogger();
    // Nothing on disk yet: the header is still sitting in the buffer
    expect(await PerfLogger.countStoredSessions(), 0);

    final path = await PerfLogger.exportAll();

    expect(path, isNotNull);
    final content = utf8.decode(
      gzip.decode(await fileSystem.file(path!).readAsBytes()),
    );
    expect(jsonDecode(content.trim())['t'], 'header');
  });

  test('timestampSlug formats with ASCII digits and padding', () {
    expect(
      PerfLogger.timestampSlug(DateTime(2026, 1, 2, 3, 4, 5)),
      '2026-01-02_03-04-05',
    );
  });
}
