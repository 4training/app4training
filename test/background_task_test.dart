import 'package:app4training/background/background_task.dart';
import 'package:app4training/data/globals.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/data/updates.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'languages_test.dart';
import 'updates_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  //DartPluginRegistrant.ensureInitialized();
  test('Test background check: no updates available', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var fakeController = FakeDownloadAssetsController();

    final ref = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      languageProvider.overrideWith(
          () => LanguageController(assetsController: fakeController)),
      languageStatusProvider.overrideWith(() => TestLanguageStatus())
    ]);
    await backgroundCheck(ref);
    expect(ref.read(updatesAvailableProvider), false);
  });

  test('Test background check: de has updates available', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var fileSystem = await createBasicFileSystem(['de', 'en']);
    var fakeController = FakeDownloadAssetsController();

    final ref = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      httpClientProvider.overrideWith((ref) => mockCheckResponse({'de': 2})),
      fileSystemProvider.overrideWith((ref) => fileSystem),
      languageProvider.overrideWith(
          () => LanguageController(assetsController: fakeController)),
    ]);

    expect(ref.read(sharedPrefsProvider).getBool('updatesAvailable-de'), null);
    await backgroundCheck(ref);
    expect(ref.read(sharedPrefsProvider).getBool('updatesAvailable-de'), true);
    expect(ref.read(languageStatusProvider('de')).updatesAvailable, true);
    expect(ref.read(sharedPrefsProvider).getBool('updatesAvailable-en'), false);
    expect(ref.read(languageStatusProvider('en')).updatesAvailable, false);
    expect(ref.read(sharedPrefsProvider).getBool('updatesAvailable-fr'), null);
    expect(ref.read(languageStatusProvider('fr')).updatesAvailable, false);
    expect(ref.read(updatesAvailableProvider), true);
  });

  test("Make sure backgroundTestMain() doesn't throw", () async {
    await backgroundTestMain();
  });

  // The rest of the background task gets tested in the integration test
  // (unfortunately that is not counted for test coverage currently...)
}
