import 'dart:async';
import 'dart:convert';
import 'dart:io' as io show Platform, ProcessInfo, gzip;
import 'dart:typed_data' show BytesBuilder;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:file/file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;

/// Compile-time switch for the performance logging feature.
///
/// Tester builds are made with
/// `flutter build apk --release --dart-define=ENABLE_PERF_LOGGING=true`.
/// In normal builds this is false and everything in this file is dead code
/// (the compiler removes the bodies behind the `enabled` checks).
///
/// Deliberately *not* kDebugMode: debug builds are 5-10x slower for the
/// CPU-bound work we are trying to measure, so
/// profiling numbers must come from release builds.
const bool kPerfLoggingEnabled = bool.fromEnvironment('ENABLE_PERF_LOGGING');

/// Keep at most this many session files on the device
const int kMaxStoredPerfSessions = 20;

/// Frames slower than this count as jank and get their own record
const int kJankThresholdUs = 16700; // ~ one 60Hz frame budget

/// At most this many individual jank records per session
/// (the frame histogram keeps counting beyond that)
const int kMaxJankRecords = 300;

/// Safety valve: never buffer more records than this in memory
const int kMaxBufferedRecords = 5000;

/// Upper bounds of the frame duration histogram buckets, in microseconds
/// (the last bucket is open-ended)
const List<int> _frameBucketLimitsUs = [16700, 33400, 66800, 133600];

/// Collects technical performance data (timing spans, jank frames, device
/// specs) into one JSONL file per app launch, for instrumented tester builds.
///
/// A static facade instead of a Riverpod provider: recording starts in
/// main() before any ProviderScope exists, and the call sites sit on hot
/// paths in code that has no `ref` (e.g. [LanguageDownloaderImpl]).
/// The file system and clock are injectable through [start] so tests can
/// use a MemoryFileSystem, like the rest of the codebase does.
///
/// Design rules:
/// - No PII: no language codes, no page names, no user identifiers.
/// - Never throws, never crashes the app: every entry point swallows errors.
/// - Writes are buffered and flushed every few seconds / on app pause, so
///   the logging can't cause the I/O jank it is supposed to measure.
class PerfLogger {
  PerfLogger._();

  /// Whether recording is active. Initialized from the compile-time flag;
  /// mutable so tests can exercise the enabled path
  /// (`flutter test` runs with the dart-define unset).
  static bool enabled = kPerfLoggingEnabled;

  /// Time source for all span offsets: microseconds since [markAppStart]
  static final Stopwatch _clock = Stopwatch();

  static FileSystem? _fileSystem;
  static String? _sessionDir;
  static String? _sessionId;
  static DateTime Function() _now = DateTime.now;
  static int Function() _rssBytes = _defaultRssBytes;
  static final List<String> _buffer = [];
  static Timer? _flushTimer;
  static bool _flushing = false;
  static TimingsCallback? _timingsCallback;
  static WidgetsBindingObserver? _lifecycleObserver;

  // Cumulative frame statistics for the current session
  static int _totalFrames = 0;
  static int _framesAtLastFlush = 0;
  static int _jankRecorded = 0;
  static int _worstFrameUs = 0;
  static final List<int> _frameBuckets = List.filled(
    _frameBucketLimitsUs.length + 1,
    0,
  );

  static int _defaultRssBytes() {
    try {
      return io.ProcessInfo.currentRss;
    } catch (_) {
      return 0;
    }
  }

  /// First statement of main(): starts the clock all span offsets are
  /// relative to, so they mean "microseconds since app start".
  static void markAppStart() {
    if (!enabled) return;
    _clock
      ..reset()
      ..start();
  }

  /// Set up the session (call as soon as the app documents dir is known).
  ///
  /// Deliberately cheap - no file is touched here. The session file is
  /// created lazily by the first [flush], and pruning old sessions happens
  /// in [attachToApp] after the first frame, so that the profiling itself
  /// doesn't distort the cold start it wants to measure.
  static void start({
    required FileSystem fileSystem,
    required String directory,
    DateTime Function()? now,
    int Function()? rssBytes,
    bool autoFlush = true,
  }) {
    if (!enabled) return;
    try {
      if (!_clock.isRunning) _clock.start();
      _fileSystem = fileSystem;
      _sessionDir = directory;
      if (now != null) _now = now;
      if (rssBytes != null) _rssBytes = rssBytes;
      final DateTime ts = _now();
      _sessionId =
          '${timestampSlug(ts)}-${ts.millisecond.toString().padLeft(3, '0')}';
      _record({
        't': 'header',
        'session': _sessionId,
        'tsUtc': ts.toUtc().toIso8601String(),
        'buildMode':
            kReleaseMode
                ? 'release'
                : kProfileMode
                ? 'profile'
                : 'debug',
      });
      _flushTimer?.cancel();
      if (autoFlush) {
        _flushTimer = Timer.periodic(
          const Duration(seconds: 5),
          (_) => flush(),
        );
      }
    } catch (e) {
      debugPrint('PerfLogger.start failed: $e');
    }
  }

  /// Call right after runApp(): records the first-frame event, starts
  /// watching frame timings, flushes when the app goes to the background
  /// and prunes old sessions once the startup is out of the way.
  static void attachToApp() {
    if (!enabled || _sessionId == null) return;
    try {
      final binding = WidgetsBinding.instance;
      binding.addPostFrameCallback((_) {
        event('firstFrame');
        unawaited(prune());
        unawaited(flush());
      });
      _timingsCallback = _onFrameTimings;
      binding.addTimingsCallback(_timingsCallback!);
      _lifecycleObserver = _PerfLifecycleFlusher();
      binding.addObserver(_lifecycleObserver!);
    } catch (e) {
      debugPrint('PerfLogger.attachToApp failed: $e');
    }
  }

  /// Record technical device and app information (no identifiers).
  /// Runs platform channels, so keep it off the critical startup path
  /// (main() fires it unawaited).
  static Future<void> logDeviceAndApp(PackageInfo packageInfo) async {
    if (!enabled) return;
    try {
      final Map<String, Object?> rec = {
        't': 'device',
        'appVersion': '${packageInfo.version}+${packageInfo.buildNumber}',
        'cpuCores': io.Platform.numberOfProcessors,
      };
      if (io.Platform.isAndroid) {
        final info = await DeviceInfoPlugin().androidInfo;
        rec.addAll({
          'os': 'android',
          'osVersion': info.version.release,
          'sdkInt': info.version.sdkInt,
          'manufacturer': info.manufacturer,
          'model': info.model,
          'ramMB': info.physicalRamSize,
          'availableRamMB': info.availableRamSize,
          'physicalDevice': info.isPhysicalDevice,
        });
      } else if (io.Platform.isIOS) {
        final info = await DeviceInfoPlugin().iosInfo;
        rec.addAll({
          'os': 'ios',
          'osVersion': info.systemVersion,
          'model': info.utsname.machine,
          'ramMB': info.physicalRamSize,
          'physicalDevice': info.isPhysicalDevice,
        });
      }
      _record(rec);
    } catch (e) {
      debugPrint('PerfLogger: recording device info failed: $e');
    }
  }

  /// Measure an asynchronous operation. Returns whatever [body] returns and
  /// rethrows whatever it throws (recording the span with `error: true`).
  ///
  /// [data] is only evaluated after [body] completed, so it can report
  /// results of the operation (e.g. how many pages were parsed).
  static Future<T> span<T>(
    String name,
    Future<T> Function() body, {
    Map<String, Object?> Function()? data,
  }) async {
    if (!enabled) return body();
    if (!_clock.isRunning) _clock.start();
    final int startUs = _clock.elapsedMicroseconds;
    bool ok = true;
    try {
      return await body();
    } catch (_) {
      ok = false;
      rethrow;
    } finally {
      _endSpan(name, startUs, ok, data);
    }
  }

  /// Measure a synchronous operation, see [span]
  static T spanSync<T>(
    String name,
    T Function() body, {
    Map<String, Object?> Function()? data,
  }) {
    if (!enabled) return body();
    if (!_clock.isRunning) _clock.start();
    final int startUs = _clock.elapsedMicroseconds;
    bool ok = true;
    try {
      return body();
    } catch (_) {
      ok = false;
      rethrow;
    } finally {
      _endSpan(name, startUs, ok, data);
    }
  }

  static void _endSpan(
    String name,
    int startUs,
    bool ok,
    Map<String, Object?> Function()? data,
  ) {
    try {
      final Map<String, Object?> rec = {
        't': 'span',
        'name': name,
        'startUs': startUs,
        'durUs': _clock.elapsedMicroseconds - startUs,
        'rssMB': (_rssBytes() / (1024 * 1024)).round(),
      };
      if (!ok) rec['error'] = true;
      if (data != null) rec.addAll(data());
      _record(rec);
    } catch (e) {
      debugPrint('PerfLogger: recording span $name failed: $e');
    }
  }

  /// Record a point-in-time occurrence
  static void event(String name, {Map<String, Object?>? data}) {
    if (!enabled) return;
    try {
      _record({
        't': 'event',
        'name': name,
        'atUs': _clock.elapsedMicroseconds,
        ...?data,
      });
    } catch (e) {
      debugPrint('PerfLogger: recording event $name failed: $e');
    }
  }

  static void _record(Map<String, Object?> rec) {
    if (_buffer.length >= kMaxBufferedRecords) return;
    _buffer.add(jsonEncode(rec));
  }

  static void _onFrameTimings(List<FrameTiming> timings) {
    if (!enabled) return;
    try {
      for (final timing in timings) {
        _totalFrames++;
        final int totalUs = timing.totalSpan.inMicroseconds;
        if (totalUs > _worstFrameUs) _worstFrameUs = totalUs;
        int bucket = 0;
        while (bucket < _frameBucketLimitsUs.length &&
            totalUs > _frameBucketLimitsUs[bucket]) {
          bucket++;
        }
        _frameBuckets[bucket]++;
        if (totalUs > kJankThresholdUs && _jankRecorded < kMaxJankRecords) {
          _jankRecorded++;
          _record({
            't': 'jank',
            'atUs': _clock.elapsedMicroseconds,
            'buildUs': timing.buildDuration.inMicroseconds,
            'rasterUs': timing.rasterDuration.inMicroseconds,
            'totalUs': totalUs,
          });
        }
      }
    } catch (_) {
      // Never let instrumentation break frame scheduling
    }
  }

  /// Write all buffered records to the session file (creating it on demand).
  /// Also emits a cumulative frame histogram record whenever new frames were
  /// rendered since the last flush - the last one in the file wins.
  static Future<void> flush() async {
    if (!enabled || _sessionId == null || _fileSystem == null) return;
    if (_flushing) return; // Drop overlapping flushes instead of interleaving
    _flushing = true;
    try {
      if (_totalFrames > _framesAtLastFlush) {
        _framesAtLastFlush = _totalFrames;
        _record({
          't': 'frames',
          'total': _totalFrames,
          'bucketsUpToMs': ['17', '33', '67', '134', 'inf'],
          'buckets': List.of(_frameBuckets),
          'worstUs': _worstFrameUs,
        });
      }
      if (_buffer.isEmpty) return;
      final String lines = '${_buffer.join('\n')}\n';
      _buffer.clear();
      final File file = _sessionFile();
      await file.parent.create(recursive: true);
      await file.writeAsString(lines, mode: FileMode.append, flush: true);
    } catch (e) {
      debugPrint('PerfLogger.flush failed: $e');
    } finally {
      _flushing = false;
    }
  }

  static File _sessionFile() =>
      _fileSystem!.file(p.join(_sessionDir!, 'session-$_sessionId.jsonl'));

  /// Delete the oldest sessions so that at most [kMaxStoredPerfSessions]
  /// (including the current one) remain. Called by [attachToApp] after the
  /// first frame; public so tests can drive it directly.
  static Future<void> prune() async {
    if (!enabled || _sessionId == null || _fileSystem == null) return;
    try {
      final List<File> files = await _listSessionFiles();
      // The current session may not have been flushed to disk yet -
      // reserve its slot either way
      final String currentPath = _sessionFile().path;
      files.removeWhere((file) => file.path == currentPath);
      while (files.length > kMaxStoredPerfSessions - 1) {
        await files.removeAt(0).delete();
      }
    } catch (e) {
      debugPrint('PerfLogger.prune failed: $e');
    }
  }

  /// Session files, sorted oldest first (their names sort chronologically)
  static Future<List<File>> _listSessionFiles() async {
    final Directory dir = _fileSystem!.directory(_sessionDir!);
    if (!await dir.exists()) return [];
    final List<File> files = [];
    await for (final entity in dir.list(followLinks: false)) {
      final String name = p.basename(entity.path);
      if (entity is File &&
          name.startsWith('session-') &&
          name.endsWith('.jsonl')) {
        files.add(entity);
      }
    }
    files.sort((a, b) => a.path.compareTo(b.path));
    return files;
  }

  /// How many sessions are stored on the device right now?
  static Future<int> countStoredSessions() async {
    if (!enabled || _fileSystem == null || _sessionDir == null) return 0;
    try {
      return (await _listSessionFiles()).length;
    } catch (_) {
      return 0;
    }
  }

  /// Concatenate all stored sessions into one gzipped file, ready to be
  /// shared: `<sessionDir>/export/app4training-perf-<timestamp>.jsonl.gz`.
  /// Older exports are removed first so they don't pile up.
  /// Returns the path of the file, or null if there is nothing to export
  /// or exporting failed.
  static Future<String?> exportAll() async {
    if (!enabled || _sessionId == null || _fileSystem == null) return null;
    try {
      await flush();
      final List<File> files = await _listSessionFiles();
      if (files.isEmpty) return null;
      final BytesBuilder bytes = BytesBuilder(copy: false);
      for (final file in files) {
        bytes.add(await file.readAsBytes());
      }
      final List<int> compressed = io.gzip.encode(bytes.takeBytes());
      final Directory exportDir = _fileSystem!.directory(
        p.join(_sessionDir!, 'export'),
      );
      if (await exportDir.exists()) {
        await exportDir.delete(recursive: true);
      }
      await exportDir.create(recursive: true);
      final File out = _fileSystem!.file(
        p.join(
          exportDir.path,
          'app4training-perf-${timestampSlug(_now())}.jsonl.gz',
        ),
      );
      await out.writeAsBytes(compressed, flush: true);
      return out.path;
    } catch (e) {
      debugPrint('PerfLogger.exportAll failed: $e');
      return null;
    }
  }

  /// `2026-08-27_14-30-05` - deliberately not intl's DateFormat, whose
  /// digits depend on the default locale (file names should stay ASCII)
  static String timestampSlug(DateTime ts) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${ts.year}-${two(ts.month)}-${two(ts.day)}'
        '_${two(ts.hour)}-${two(ts.minute)}-${two(ts.second)}';
  }

  /// Undo everything (for tests): cancel timers, detach from the binding,
  /// forget the session and restore the compile-time enabled state.
  @visibleForTesting
  static Future<void> reset() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    if (_timingsCallback != null) {
      try {
        SchedulerBinding.instance.removeTimingsCallback(_timingsCallback!);
      } catch (_) {}
      _timingsCallback = null;
    }
    if (_lifecycleObserver != null) {
      try {
        WidgetsBinding.instance.removeObserver(_lifecycleObserver!);
      } catch (_) {}
      _lifecycleObserver = null;
    }
    _buffer.clear();
    _sessionId = null;
    _sessionDir = null;
    _fileSystem = null;
    _now = DateTime.now;
    _rssBytes = _defaultRssBytes;
    _clock
      ..stop()
      ..reset();
    _totalFrames = 0;
    _framesAtLastFlush = 0;
    _jankRecorded = 0;
    _worstFrameUs = 0;
    _frameBuckets.fillRange(0, _frameBuckets.length, 0);
    enabled = kPerfLoggingEnabled;
  }
}

/// Flush the record buffer whenever the app leaves the foreground -
/// on Android that's the last reliable moment before the process may die
class _PerfLifecycleFlusher with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(PerfLogger.flush());
    }
  }
}
