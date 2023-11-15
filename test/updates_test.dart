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

  test('Test LanguageStatus', () {
    final container = ProviderContainer(overrides: [
      languageProvider.overrideWith(() =>
          LanguageController(assetsController: FakeDownloadAssetsController())),
    ]);
    LanguageStatus deStatus = container.read(languageStatusProvider('de'));
    expect(deStatus.downloadTimestamp, equals(DateTime.utc(2023, 1, 1)));
    expect(deStatus.lastCheckedTimestamp, equals(DateTime.utc(2023, 1, 1)));
    final deStatusNotifier =
        container.read(languageStatusProvider('de').notifier);
    deStatusNotifier.check();
  });
  test('Test checking for updates: no updates', () async {
    final container = ProviderContainer(overrides: [
      httpClientProvider.overrideWith((ref) => MockClient((request) async {
            expect(
                request.url.toString(),
                equals(
                    Globals.getCommitsSince('de', DateTime.utc(2023, 1, 1))));
            return Response(json.encode([]), 200);
          })),
      languageProvider.overrideWith(() =>
          LanguageController(assetsController: FakeDownloadAssetsController())),
    ]);
    LanguageStatus deStatus = container.read(languageStatusProvider('de'));
    expect(deStatus.downloadTimestamp, equals(DateTime.utc(2023, 1, 1)));
    expect(deStatus.lastCheckedTimestamp, equals(DateTime.utc(2023, 1, 1)));
    final deStatusNotifier =
        container.read(languageStatusProvider('de').notifier);
    expect(await deStatusNotifier.check(), 0);

    // The lastCheckedTimestamp should be updated to the current time now()
    deStatus = container.read(languageStatusProvider('de'));
    expect(deStatus.downloadTimestamp, equals(DateTime.utc(2023, 1, 1)));
    expect(
        deStatus.lastCheckedTimestamp, isNot(equals(DateTime.utc(2023, 1, 1))));
    expect(deStatus.updatesAvailable, false);
  });

  test('Test checking for updates: 2 updates', () async {
    final container = ProviderContainer(overrides: [
      httpClientProvider.overrideWith((ref) => MockClient((request) async {
            expect(
                request.url.toString(),
                equals(
                    Globals.getCommitsSince('de', DateTime.utc(2023, 1, 1))));
            // The real response is more complex but as we don't care about
            // all the properties that's enough to simulate two new commits
            return Response(json.encode([0, 1]), 200);
          })),
      languageProvider.overrideWith(() =>
          LanguageController(assetsController: FakeDownloadAssetsController())),
    ]);
    final deStatusNotifier =
        container.read(languageStatusProvider('de').notifier);
    expect(await deStatusNotifier.check(), 2);

    // The lastCheckedTimestamp should be updated to the current time now()
    LanguageStatus deStatus = container.read(languageStatusProvider('de'));
    expect(deStatus.downloadTimestamp, equals(DateTime.utc(2023, 1, 1)));
    expect(
        deStatus.lastCheckedTimestamp, isNot(equals(DateTime.utc(2023, 1, 1))));
    expect(deStatus.updatesAvailable, true);

    // If we check for updates a second time, we should get the same results
    expect(await deStatusNotifier.check(), 2);
    deStatus = container.read(languageStatusProvider('de'));
    expect(deStatus.downloadTimestamp, equals(DateTime.utc(2023, 1, 1)));
    expect(
        deStatus.lastCheckedTimestamp, isNot(equals(DateTime.utc(2023, 1, 1))));
    expect(deStatus.updatesAvailable, true);
  });

  test('Test checking and updating', () async {
    SharedPreferences.setMockInitialValues({'download_de': false});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      httpClientProvider.overrideWith((ref) => MockClient((request) async {
            expect(
                request.url.toString(),
                equals(
                    Globals.getCommitsSince('de', DateTime.utc(2023, 1, 1))));
            // The real response is more complex but as we don't care about
            // all the properties that's enough to simulate two new commits
            return Response(json.encode([0, 1]), 200);
          })),
      languageProvider.overrideWith(() =>
          LanguageController(assetsController: FakeDownloadAssetsController())),
    ]);

    final deStatusNotifier =
        container.read(languageStatusProvider('de').notifier);
    expect(await deStatusNotifier.check(), 2);

    // The lastCheckedTimestamp should be updated to the current time now()
    LanguageStatus deStatus = container.read(languageStatusProvider('de'));
    expect(deStatus.downloadTimestamp, equals(DateTime.utc(2023, 1, 1)));
    expect(
        deStatus.lastCheckedTimestamp, isNot(equals(DateTime.utc(2023, 1, 1))));
    expect(deStatus.updatesAvailable, true);

    // Mock downloading the resources (no problem that it throws)
    try {
      await container
          .read(languageProvider('de').notifier)
          .download(force: true);
      fail('download() should throw because no files are there');
    } catch (e) {
      expect(e, isA<Exception>());
    }
    deStatus = container.read(languageStatusProvider('de'));
    expect(deStatus.updatesAvailable, false);
  });

  // TODO: Test check() throwing an exception
  // TODO: Test availableUpdatesProvider
}
