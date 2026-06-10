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

    // Order is not guaranteed with a worker pool, only that all are processed.
    expect(processed, unorderedEquals(['de', 'en', 'fr']));
    expect(result.successCount, 3);
    expect(result.errorCount, 0);
    expect(['de', 'en', 'fr'], contains(result.lastSuccessCode));
  });

  test('aggregates successes and failures', () async {
    final result = await downloadLanguagesInParallel(
      ['de', 'en', 'fr'],
      maxConcurrent: 4,
      download: (code) async => code != 'en',
    );

    expect(result.successCount, 2);
    expect(result.errorCount, 1);
    expect(['de', 'fr'], contains(result.lastSuccessCode));
  });

  test('counts a throwing download as an error without aborting the rest',
      () async {
    final result = await downloadLanguagesInParallel(
      ['de', 'en', 'fr'],
      maxConcurrent: 4,
      download: (code) async {
        if (code == 'en') throw Exception('boom');
        return true;
      },
    );

    expect(result.successCount, 2);
    expect(result.errorCount, 1);
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

  test('keeps the pool full instead of stalling on a slow download', () async {
    final slowGate = Completer<void>();
    final completed = <String>[];

    final future = downloadLanguagesInParallel(
      ['slow', 'a', 'b', 'c'],
      maxConcurrent: 2,
      download: (code) async {
        if (code == 'slow') {
          await slowGate.future;
        }
        completed.add(code);
        return true;
      },
    );

    // While 'slow' is still blocked, the second worker should drain all the
    // remaining fast downloads. A batched implementation would stall here.
    while (completed.length < 3) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(completed, containsAll(['a', 'b', 'c']));
    expect(completed, isNot(contains('slow')));

    slowGate.complete();
    final result = await future;
    expect(result.successCount, 4);
  });

  test('uses default maxConcurrent constant', () async {
    expect(kMaxParallelLanguageDownloads, 4);
  });
}
