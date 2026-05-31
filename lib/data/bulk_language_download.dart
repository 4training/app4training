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

/// Download or update [languageCodes] with at most [maxConcurrent] in flight.
Future<BulkDownloadResult> downloadLanguagesInParallel(
  Iterable<String> languageCodes, {
  required LanguageDownloadFn download,
  int maxConcurrent = kMaxParallelLanguageDownloads,
}) async {
  final codes = languageCodes.toList();
  var successCount = 0;
  var errorCount = 0;
  var lastSuccessCode = '';

  for (var i = 0; i < codes.length; i += maxConcurrent) {
    final batch = codes.skip(i).take(maxConcurrent).toList();
    final results = await Future.wait(
      batch.map((code) async {
        final success = await download(code);
        return (code, success);
      }),
    );
    for (final (code, success) in results) {
      if (success) {
        successCount++;
        lastSuccessCode = code;
      } else {
        errorCount++;
      }
    }
  }

  return BulkDownloadResult(
    successCount: successCount,
    errorCount: errorCount,
    lastSuccessCode: lastSuccessCode,
  );
}
