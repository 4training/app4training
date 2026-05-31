import 'dart:async';

import 'package:app4training/data/bulk_language_download.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('processes all language codes', () async {
    final processed = <String>[];
    final result = await downloadLanguagesInParallel(
      ['de', 'en', 'fr'],
      maxConcurrent: 4,
      download: (code) async {
        processed.add(code);
        return true;
      },
    );

    expect(processed, ['de', 'en', 'fr']);
    expect(result.successCount, 3);
    expect(result.errorCount, 0);
    expect(result.lastSuccessCode, 'fr');
  });

  test('aggregates successes and failures', () async {
    final result = await downloadLanguagesInParallel(
      ['de', 'en', 'fr'],
      maxConcurrent: 4,
      download: (code) async => code != 'en',
    );

    expect(result.successCount, 2);
    expect(result.errorCount, 1);
    expect(result.lastSuccessCode, 'fr');
  });

  test('never exceeds maxConcurrent in flight', () async {
    var inFlight = 0;
    var maxObserved = 0;
    final gate = Completer<void>();

    final future = downloadLanguagesInParallel(
      List.generate(10, (i) => 'lang$i'),
      maxConcurrent: 4,
      download: (code) async {
        inFlight++;
        maxObserved = maxObserved < inFlight ? inFlight : maxObserved;
        await gate.future;
        inFlight--;
        return true;
      },
    );

    while (maxObserved < 4) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(maxObserved, 4);

    gate.complete();
    final result = await future;
    expect(result.successCount, 10);
  });

  test('uses default maxConcurrent constant', () async {
    expect(kMaxParallelLanguageDownloads, 4);
  });
}
