import 'dart:collection';

const kMaxParallelLanguageDownloads = 4;

typedef LanguageDownloadFn = Future<bool> Function(String languageCode);

class BulkDownloadResult {
  final int successCount;
  final int errorCount;
  final String lastSuccessCode;

  const BulkDownloadResult({
    required this.successCount,
    required this.errorCount,
    required this.lastSuccessCode,
  });
}

/// Download or update [languageCodes] keeping at most [maxConcurrent] in
/// flight at any time. Uses a worker pool: as soon as one download finishes a
/// new one is started, so a slow language never blocks idle slots.
Future<BulkDownloadResult> downloadLanguagesInParallel(
  Iterable<String> languageCodes, {
  required LanguageDownloadFn download,
  int maxConcurrent = kMaxParallelLanguageDownloads,
}) async {
  assert(maxConcurrent > 0);
  final queue = Queue<String>.of(languageCodes);
  var successCount = 0;
  var errorCount = 0;
  var lastSuccessCode = '';

  // Each worker pulls the next code until the queue is empty. Safe without
  // locking: there's no await between isNotEmpty and removeFirst, and Dart is
  // single-threaded.
  Future<void> worker() async {
    while (queue.isNotEmpty) {
      final code = queue.removeFirst();
      bool success;
      try {
        success = await download(code);
      } catch (_) {
        success = false;
      }
      if (success) {
        successCount++;
        lastSuccessCode = code;
      } else {
        errorCount++;
      }
    }
  }

  await Future.wait([
    for (var i = 0; i < maxConcurrent; i++) worker(),
  ]);

  return BulkDownloadResult(
    successCount: successCount,
    errorCount: errorCount,
    lastSuccessCode: lastSuccessCode,
  );
}
