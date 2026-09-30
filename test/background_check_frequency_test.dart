import 'package:app4training/background/background_task.dart';
import 'package:app4training/background/background_test.dart';
import 'package:app4training/data/globals.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/data/updates.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'languages_test.dart';
import 'updates_test.dart';

/// German is downloaded (and therefore last checked) right now;
/// [httpCalls] counts every request to the GitHub API
Future<({ProviderContainer ref, List<Uri> httpCalls})> setup(
  CheckFrequency checkFrequency,
) async {
  SharedPreferences.setMockInitialValues({
    'checkFrequency': checkFrequency.name,
  });
  final prefs = await SharedPreferences.getInstance();
  final fileSystem = await createBasicFileSystem(['de']);
  final httpCalls = <Uri>[];

  final ref = ProviderContainer(
    overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      fileSystemProvider.overrideWith((ref) => fileSystem),
      languageDownloaderProvider.overrideWithValue(
        FakeLanguageDownloader(fileSystem: fileSystem),
      ),
      connectivityServiceProvider.overrideWithValue(
        FakeConnectivityService(unmetered: true),
      ),
      httpClientProvider.overrideWithValue(
        MockClient((request) async {
          httpCalls.add(request.url);
          return fakeResponseNUpdates(0);
        }),
      ),
    ],
  );
  return (ref: ref, httpCalls: httpCalls);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'weekly: a run 2 days after the last check makes no network calls',
    () async {
      final s = await setup(CheckFrequency.weekly);
      await backgroundRun(
        s.ref,
        now: DateTime.now().toUtc().add(const Duration(days: 2)),
      );
      expect(s.httpCalls, isEmpty);
    },
  );

  test(
    'weekly: a run a week after the last check checks for updates',
    () async {
      final s = await setup(CheckFrequency.weekly);
      await backgroundRun(
        s.ref,
        now: DateTime.now().toUtc().add(const Duration(days: 8)),
      );
      expect(s.httpCalls, hasLength(1));
    },
  );

  test('Android: a run scheduled one interval after the previous run started '
      'is not skipped, although lastChecked was written a bit later', () async {
    final s = await setup(CheckFrequency.weekly);
    await backgroundRun(
      s.ref,
      now: DateTime.now().toUtc().add(
        const Duration(days: 7) - const Duration(minutes: 5),
      ),
    );
    expect(s.httpCalls, hasLength(1));
  });

  test(
    'never: a stray run (e.g. a leftover iOS registration) does nothing',
    () async {
      final s = await setup(CheckFrequency.never);
      await backgroundRun(
        s.ref,
        now: DateTime.now().toUtc().add(const Duration(days: 365)),
      );
      expect(s.httpCalls, isEmpty);
    },
  );

  group('Skip / run decision for each CheckFrequency', () {
    for (final frequency in CheckFrequency.values) {
      final interval = frequency.getDuration();
      if (interval == null) continue; // never: tested above
      test('${frequency.name}: skip after half the interval', () async {
        final s = await setup(frequency);
        await backgroundRun(
          s.ref,
          now: DateTime.now().toUtc().add(interval ~/ 2),
        );
        expect(s.httpCalls, isEmpty);
      });
      test('${frequency.name}: run after the full interval', () async {
        final s = await setup(frequency);
        await backgroundRun(s.ref, now: DateTime.now().toUtc().add(interval));
        expect(s.httpCalls, hasLength(1));
      });
    }
  });

  test('iOS: with weekly, daily wake-ups only check on the 7th day', () async {
    final s = await setup(CheckFrequency.weekly);
    final start = DateTime.now().toUtc();
    for (int day = 1; day <= 6; day++) {
      await backgroundRun(s.ref, now: start.add(Duration(days: day)));
    }
    expect(s.httpCalls, isEmpty);
    await backgroundRun(s.ref, now: start.add(const Duration(days: 7)));
    expect(s.httpCalls, hasLength(1));
  });
}
