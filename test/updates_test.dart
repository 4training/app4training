import 'dart:convert';

import 'package:app4training/data/globals.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app4training/data/updates.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'languages_test.dart';

int countCheckCalled = 0;

/// For mocking languageStatusProvider: doesn't access SharedPreferences
/// and you can define behavior (return value) of the check() method.
///
/// With the optional parameter langsWithUpdates you can simulate that
/// certain languages have updates available right from the beginning
/// (this is ignored for check() though).
///
/// This doesn't access languageProvider, so it doesn't take into account
/// whether the language is actually downloaded and it doesn't get rebuilt
/// when a Language gets rebuilt - if you need to test such complex behavior,
/// use the real LanguageStatusNotifier and override sharedPreferencesProvider
class TestLanguageStatus extends LanguageStatusNotifier {
  int _checkReturnValue;
  final List<String> _langWithUpdates;
  TestLanguageStatus(
      {int checkReturnValue = 0, List<String> langWithUpdates = const []})
      : _checkReturnValue = checkReturnValue,
        _langWithUpdates = langWithUpdates;

  @override
  LanguageStatus build(String arg) {
    return LanguageStatus(
        _langWithUpdates.contains(arg), DateTime.utc(2023), DateTime.utc(2023));
  }

  @override
  Future<int> check() async {
    countCheckCalled++;
    if (_checkReturnValue >= 0) {
      state = LanguageStatus(_checkReturnValue > 0, state.downloadTimestamp,
          DateTime.now().toUtc());
    }
    return _checkReturnValue;
  }

  void setCheckReturnValue(int returnValue) {
    _checkReturnValue = returnValue;
  }
}

// Fake HTTP response: no updates available
Response fakeResponseNoUpdates() {
  return Response(json.encode([]), 200);
}

// Fake HTTP response: two updates available
// The real response is more complex but as we don't care about
// all the properties that's enough to simulate two new commits
Response fakeResponseTwoUpdates() {
  return Response(json.encode([0, 1]), 200);
}

// Fake HTTP response: [count] updates available
// Again, the real response is more complex but for us this is enough
Response fakeResponseNUpdates(int count) {
  List<int> response = [];
  for (int i = 0; i < count; i++) {
    response.add(i);
  }
  return Response(json.encode(response), 200);
}

/// Mock checking for updates: returns that we have two updates available
Client mockReturnTwoUpdates() {
  return MockClient((request) async {
    return fakeResponseTwoUpdates();
  });
}

/// Mock checking for updates: allow different responses for different languages
/// e.g. with parameter {'de': 0, 'en': 2, 'fr': 1}
/// languages not found in the map will default to 0 updates
Client mockCheckResponse(Map<String, int> languageUpdateMap) {
  return MockClient((request) async {
    // Get our language code from the URL that looks something like this:
    // https://api.github.com/repos/4training/html-de/commits?since=...
    final String languageCode = request.url.pathSegments
        .firstWhere((element) => element.startsWith('html-'),
            orElse: () => 'html-xyz')
        .substring(5);
    int countUpdates = languageUpdateMap[languageCode] ?? 0;
    return fakeResponseNUpdates(countUpdates);
  });
}

void main() {
  test('Test stringToCheckFrequency: graceful error handling', () {
    expect(CheckFrequency.fromString('never'), CheckFrequency.never);
    expect(CheckFrequency.fromString('daily'), CheckFrequency.daily);
    expect(CheckFrequency.fromString('weekly'), CheckFrequency.weekly);
    expect(CheckFrequency.fromString('monthly'), CheckFrequency.monthly);
    expect(CheckFrequency.fromString('weird'), CheckFrequency.weekly);
    expect(CheckFrequency.fromString(null), CheckFrequency.weekly);
  });

  testWidgets('Test getting localized messages', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(
        child: MaterialApp(
            locale: Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold())));
    BuildContext context = tester.element(find.byType(Scaffold));
    expect(
        CheckFrequency.getLocalized(context, CheckFrequency.never), "niemals");
  });

  test('Test TestLanguageStatusNotifier class', () async {
    var testLanguageStatus = TestLanguageStatus();
    var ref = ProviderContainer(overrides: [
      languageStatusProvider.overrideWith(() => testLanguageStatus)
    ]);
    var deStatus = ref.read(languageStatusProvider('de'));
    expect(deStatus.updatesAvailable, false);
    expect(deStatus.lastCheckedTimestamp, equals(deStatus.downloadTimestamp));
    expect(await ref.read(languageStatusProvider('de').notifier).check(), 0);
    deStatus = ref.read(languageStatusProvider('de'));
    expect(deStatus.updatesAvailable, false);
    expect(deStatus.lastCheckedTimestamp.compareTo(deStatus.downloadTimestamp),
        greaterThan(0));

    testLanguageStatus.setCheckReturnValue(2);
    await Future.delayed(const Duration(milliseconds: 1));
    expect(await ref.read(languageStatusProvider('de').notifier).check(), 2);
    var deStatus2 = ref.read(languageStatusProvider('de'));
    expect(deStatus2.updatesAvailable, true);
    expect(deStatus2.downloadTimestamp, equals(deStatus.downloadTimestamp));
    // last checked timestamp should be even newer
    expect(
        deStatus2.lastCheckedTimestamp.compareTo(deStatus.lastCheckedTimestamp),
        greaterThan(0));

    testLanguageStatus.setCheckReturnValue(-1);
    await Future.delayed(const Duration(milliseconds: 1));
    expect(await ref.read(languageStatusProvider('de').notifier).check(), -1);
    var deStatus3 = ref.read(languageStatusProvider('de'));
    expect(deStatus3.updatesAvailable, true);
    expect(deStatus3.downloadTimestamp, equals(deStatus.downloadTimestamp));
    // last checked timestamp should be the same
    expect(
        deStatus3.lastCheckedTimestamp, equals(deStatus2.lastCheckedTimestamp));

    testLanguageStatus.setCheckReturnValue(0);
    await Future.delayed(const Duration(milliseconds: 1));
    expect(await ref.read(languageStatusProvider('de').notifier).check(), 0);
    var deStatus4 = ref.read(languageStatusProvider('de'));
    expect(deStatus4.updatesAvailable, false);
    expect(deStatus4.downloadTimestamp, equals(deStatus.downloadTimestamp));
    // last checked timestamp should be newer
    expect(
        deStatus4.lastCheckedTimestamp
            .compareTo(deStatus3.lastCheckedTimestamp),
        greaterThan(0));
  });
  test('Test TestLanguageStatusNotifier constructor parameter checkReturnValue',
      () async {
    final ref = ProviderContainer(overrides: [
      languageStatusProvider
          .overrideWith(() => TestLanguageStatus(checkReturnValue: 2))
    ]);
    expect(ref.read(languageStatusProvider('de')).updatesAvailable, false);
    expect(await ref.read(languageStatusProvider('de').notifier).check(), 2);
    expect(ref.read(languageStatusProvider('de')).updatesAvailable, true);
    expect(ref.read(languageStatusProvider('en')).updatesAvailable, false);
  });
  test('Test TestLanguageStatusNotifier constructor parameter langsWithUpdates',
      () async {
    var ref = ProviderContainer(overrides: [
      languageStatusProvider
          .overrideWith(() => TestLanguageStatus(langWithUpdates: ['de']))
    ]);
    expect(ref.read(languageStatusProvider('de')).updatesAvailable, true);
    expect(ref.read(languageStatusProvider('en')).updatesAvailable, false);
  });

  group('Test reading LanguageStatus from SharedPreferences', () {
    late ProviderContainer ref;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      ref = ProviderContainer(overrides: [
        languageProvider.overrideWith(
            () => TestLanguageController(downloadedLanguages: ['de'])),
        sharedPrefsProvider.overrideWith((ref) => prefs)
      ]);
    });

    test('Nothing saved in SharedPreferences', () async {
      final deStatus = ref.read(languageStatusProvider('de'));
      expect(deStatus.downloadTimestamp, equals(DateTime.utc(2023)));
      expect(deStatus.lastCheckedTimestamp, equals(DateTime.utc(2023)));
      expect(deStatus.updatesAvailable, false);
      expect(deStatus.lastCheckedTimestamp.isUtc, true);
    });

    test('Correct values in SharedPreferences: updates', () async {
      await prefs.setString('lastChecked-de', '2023-02-02 00:00:00.000Z');
      await prefs.setBool('updatesAvailable-de', true);
      final deStatus = ref.read(languageStatusProvider('de'));
      expect(deStatus.downloadTimestamp, equals(DateTime.utc(2023)));
      expect(deStatus.lastCheckedTimestamp, equals(DateTime.utc(2023, 2, 2)));
      expect(ref.read(lastCheckedProvider), equals(DateTime.utc(2023, 2, 2)));
      expect(deStatus.updatesAvailable, true);
    });

    test('Correct values in SharedPreferences: no updates', () async {
      await prefs.setString('lastChecked-de', '2023-02-02 00:00:00.000Z');
      await prefs.setBool('updatesAvailable-de', false);
      final deStatus = ref.read(languageStatusProvider('de'));
      expect(deStatus.downloadTimestamp, equals(DateTime.utc(2023)));
      expect(deStatus.lastCheckedTimestamp, equals(DateTime.utc(2023, 2, 2)));
      expect(deStatus.updatesAvailable, false);
    });

    test('Verify that result is always UTC', () async {
      await prefs.setString('lastChecked-de', '2023-02-03T03:00:00+0300');
      final deStatus = ref.read(languageStatusProvider('de'));
      expect(deStatus.lastCheckedTimestamp, equals(DateTime.utc(2023, 2, 3)));
      expect(deStatus.lastCheckedTimestamp.isUtc, true);
      expect(ref.read(lastCheckedProvider), equals(DateTime.utc(2023, 2, 3)));
    });

    test('Testing invalid input for the lastChecked timestamp', () async {
      await prefs.setString('lastChecked-de', 'invalid');
      final deStatus = ref.read(languageStatusProvider('de'));
      expect(deStatus.lastCheckedTimestamp, deStatus.downloadTimestamp);
    });

    test('Testing too old input for the lastChecked timestamp', () async {
      await prefs.setString('lastChecked-de', '2022-01-01');
      final deStatus = ref.read(languageStatusProvider('de'));
      expect(deStatus.lastCheckedTimestamp, deStatus.downloadTimestamp);
      expect(ref.read(lastCheckedProvider), equals(DateTime.utc(2023)));
    });

    test('Testing timestamp with date in the future', () async {
      DateTime futureDate = DateTime.now().add(const Duration(days: 1));
      await prefs.setString('lastChecked-de', futureDate.toIso8601String());
      final deStatus = ref.read(languageStatusProvider('de'));
      expect(deStatus.lastCheckedTimestamp, deStatus.downloadTimestamp);
      expect(ref.read(lastCheckedProvider), equals(DateTime.utc(2023)));
    });
  });

  test('Test checking for updates: no updates', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final ref = ProviderContainer(overrides: [
      httpClientProvider.overrideWith((ref) => MockClient((request) async {
            expect(request.url.toString(),
                equals(Globals.getCommitsSince('de', DateTime.utc(2023))));
            return Response(json.encode([]), 200);
          })),
      languageProvider.overrideWith(
          () => TestLanguageController(downloadedLanguages: ['de'])),
      sharedPrefsProvider.overrideWith((ref) => prefs)
    ]);
    LanguageStatus deStatus = ref.read(languageStatusProvider('de'));
    expect(deStatus.downloadTimestamp, equals(DateTime.utc(2023)));
    expect(deStatus.lastCheckedTimestamp, equals(DateTime.utc(2023)));
    expect(ref.read(lastCheckedProvider), equals(DateTime.utc(2023)));
    expect(prefs.getBool('updatesAvailable-de'), null);
    expect(await ref.read(languageStatusProvider('de').notifier).check(), 0);

    // The lastCheckedTimestamp should be updated to the current time now()
    deStatus = ref.read(languageStatusProvider('de'));
    expect(deStatus.downloadTimestamp, equals(DateTime.utc(2023)));
    expect(deStatus.lastCheckedTimestamp.compareTo(deStatus.downloadTimestamp),
        greaterThan(0));
    expect(
        ref.read(lastCheckedProvider), equals(deStatus.lastCheckedTimestamp));
    expect(deStatus.updatesAvailable, false);
    expect(prefs.getBool('updatesAvailable-de'), false);
    expect(prefs.getString('lastChecked-de'),
        equals(deStatus.lastCheckedTimestamp.toIso8601String()));
  });

  test('Test checking for updates: 2 updates', () async {
    SharedPreferences.setMockInitialValues({
      'lastChecked-de': '2023-02-02 00:00:00.000Z',
      'updatesAvailable-de': false
    });
    final prefs = await SharedPreferences.getInstance();
    final ref = ProviderContainer(overrides: [
      httpClientProvider.overrideWith((ref) => mockReturnTwoUpdates()),
      languageProvider.overrideWith(
          () => TestLanguageController(downloadedLanguages: ['de', 'en'])),
      sharedPrefsProvider.overrideWith((ref) => prefs)
    ]);
    final deStatusNotifier = ref.read(languageStatusProvider('de').notifier);
    expect(ref.read(lastCheckedProvider), equals(DateTime.utc(2023)));
    expect(await deStatusNotifier.check(), 2);

    // lastCheckedTimestamp should be updated to the current time now()
    LanguageStatus deStatus = ref.read(languageStatusProvider('de'));
    expect(deStatus.downloadTimestamp, equals(DateTime.utc(2023)));
    expect(deStatus.lastCheckedTimestamp.compareTo(deStatus.downloadTimestamp),
        greaterThan(0));
    expect(deStatus.updatesAvailable, true);
    expect(prefs.getBool('updatesAvailable-de'), true);
    expect(prefs.getString('lastChecked-de'),
        equals(deStatus.lastCheckedTimestamp.toIso8601String()));

    // If we check for updates a second time, we should get the same results
    expect(await deStatusNotifier.check(), 2);
    deStatus = ref.read(languageStatusProvider('de'));
    expect(deStatus.downloadTimestamp, equals(DateTime.utc(2023)));
    expect(deStatus.lastCheckedTimestamp.compareTo(deStatus.downloadTimestamp),
        greaterThan(0));
    expect(deStatus.updatesAvailable, true);
    expect(prefs.getBool('updatesAvailable-de'), true);
    expect(prefs.getString('lastChecked-de'),
        equals(deStatus.lastCheckedTimestamp.toIso8601String()));

    // As we didn't check for updates for English:
    expect(ref.read(lastCheckedProvider), equals(DateTime.utc(2023)));
  });

  test('Test checking and updating', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final ref = ProviderContainer(overrides: [
      httpClientProvider.overrideWith((ref) => mockReturnTwoUpdates()),
      languageProvider.overrideWith(
          () => TestLanguageController(downloadedLanguages: ['de', 'en'])),
      sharedPrefsProvider.overrideWith((ref) => prefs)
    ]);

    expect(await ref.read(languageStatusProvider('de').notifier).check(), 2);

    // The lastCheckedTimestamp should be updated to the current time now()
    LanguageStatus deStatus = ref.read(languageStatusProvider('de'));
    expect(deStatus.downloadTimestamp, equals(DateTime.utc(2023)));
    expect(deStatus.lastCheckedTimestamp.compareTo(deStatus.downloadTimestamp),
        greaterThan(0));
    expect(deStatus.updatesAvailable, true);
    expect(ref.read(sharedPrefsProvider).getBool('updatesAvailable-de'), true);
    expect(ref.read(lastCheckedProvider), equals(DateTime.utc(2023)));

    // check() and download() should not happen at the very same timestamp
    await Future.delayed(const Duration(milliseconds: 1));

    // Checking for updates for English -> lastCheckedProvider be newer now
    expect(await ref.read(languageStatusProvider('en').notifier).check(), 2);
    final englishTimestamp =
        ref.read(languageStatusProvider('en')).lastCheckedTimestamp;
    expect(
        ref.read(lastCheckedProvider), equals(deStatus.lastCheckedTimestamp));

    // After downloading the resources there shouldn't be updates available
    await Future.delayed(const Duration(milliseconds: 1));
    await ref.read(languageProvider('de').notifier).download(force: true);
    deStatus = ref.read(languageStatusProvider('de'));
    expect(deStatus.updatesAvailable, false);
    expect(deStatus.downloadTimestamp, equals(deStatus.lastCheckedTimestamp));
    expect(ref.read(sharedPrefsProvider).getBool('updatesAvailable-de'), false);

    // lastCheckedProvider should have advanced a little bit again
    expect(ref.read(lastCheckedProvider), equals(englishTimestamp));
    expect(
        ref.read(lastCheckedProvider).compareTo(deStatus.lastCheckedTimestamp),
        lessThan(0));
  });

  test('Test correct behavior when checking for updates fails', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final ref = ProviderContainer(overrides: [
      httpClientProvider.overrideWith((ref) => MockClient((request) async {
            throw ClientException;
          })),
      languageProvider.overrideWith(() => TestLanguageController()),
      sharedPrefsProvider.overrideWith((ref) => prefs)
    ]);

    expect(await ref.read(languageStatusProvider('de').notifier).check(), -1);

    // The lastCheckedTimestamp should not be changed
    LanguageStatus deStatus = ref.read(languageStatusProvider('de'));
    expect(deStatus.downloadTimestamp, equals(DateTime.utc(2023)));
    expect(deStatus.lastCheckedTimestamp, equals(DateTime.utc(2023)));
    expect(deStatus.updatesAvailable, false);
    expect(ref.read(sharedPrefsProvider).getBool('updatesAvailable-de'), null);
  });

  test('Test error handling when API query limit is exceeded', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final ref = ProviderContainer(overrides: [
      httpClientProvider.overrideWith((ref) => MockClient((request) async {
            return Response(
                json.encode({
                  "message":
                      "API rate limit exceeded for 1.1.1.1. (But here's the good news: Authenticated requests get a higher rate limit. Check out the documentation for more details.)",
                  "documentation_url":
                      "https://docs.github.com/rest/overview/resources-in-the-rest-api#rate-limiting"
                }),
                403);
          })),
      languageProvider.overrideWith(() => TestLanguageController()),
      sharedPrefsProvider.overrideWith((ref) => prefs)
    ]);
    expect(await ref.read(languageStatusProvider('de').notifier).check(),
        apiRateLimitExceeded);

    final deStatus = ref.read(languageStatusProvider('de'));
    expect(deStatus.downloadTimestamp, equals(DateTime.utc(2023)));
    expect(deStatus.lastCheckedTimestamp, equals(equals(DateTime.utc(2023))));
    expect(deStatus.updatesAvailable, false);
    expect(ref.read(sharedPrefsProvider).getBool('updatesAvailable-de'), null);
  });

  test('Test updatesAvailableProvider', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final ref = ProviderContainer(overrides: [
      httpClientProvider.overrideWith((ref) => mockReturnTwoUpdates()),
      languageProvider.overrideWith(() => TestLanguageController()),
      sharedPrefsProvider.overrideWith((ref) => prefs)
    ]);

    // No updates available
    LanguageStatus deStatus = ref.read(languageStatusProvider('de'));
    expect(deStatus.updatesAvailable, false);
    expect(ref.read(updatesAvailableProvider), false);

    // An update for German is available
    expect(await ref.read(languageStatusProvider('de').notifier).check(), 2);
    deStatus = ref.read(languageStatusProvider('de'));
    expect(deStatus.updatesAvailable, true);
    expect(ref.read(updatesAvailableProvider), true);

    // check() and download() should not happen at the very same timestamp
    await Future.delayed(const Duration(milliseconds: 1));

    // Updating the German resources
    expect(
        await ref.read(languageProvider('de').notifier).download(force: true),
        true);

    // Now there should again be no updates available
    deStatus = ref.read(languageStatusProvider('de'));
    expect(deStatus.updatesAvailable, false);
    expect(ref.read(updatesAvailableProvider), false);
  });
}
