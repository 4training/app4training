import 'package:app4training/background/background_result.dart';
import 'package:app4training/data/globals.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/data/updates.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'languages_test.dart';

void main() {
  test('No background activity', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final ref = ProviderContainer(overrides: [
      languageProvider.overrideWith(() => TestLanguageController()),
      sharedPrefsProvider.overrideWith((ref) => prefs)
    ]);

    expect(await ref.read(backgroundResultProvider.notifier).checkForActivity(),
        false);
  });

  test('There was some background activity', () async {
    final oldTime = DateTime(2023, 2, 2).toUtc();
    SharedPreferences.setMockInitialValues(
        {'lastChecked-de': oldTime.toIso8601String()});
    final prefs = await SharedPreferences.getInstance();

    final ref = ProviderContainer(overrides: [
      languageProvider.overrideWith(() => TestLanguageController()),
      sharedPrefsProvider.overrideWith((ref) => prefs)
    ]);

    expect(await ref.read(backgroundResultProvider.notifier).checkForActivity(),
        false);

    // Now we change the lastChecked timestamp for German
    final currentTime = DateTime.now().toUtc();
    await prefs.setString('lastChecked-de', currentTime.toIso8601String());
    expect(ref.read(languageStatusProvider('de')).lastCheckedTimestamp,
        equals(oldTime));

    expect(await ref.read(backgroundResultProvider.notifier).checkForActivity(),
        true);

//  TODO: It would probably be good if checkForActivity also updates
//  the language status providers if necessary
//    expect(ref.read(languageStatusProvider('de')).lastCheckedTimestamp,
//        equals(currentTime));
  });

  test('Test edge case: invalid values', () async {
    final oldTime = DateTime(2023, 2, 2).toUtc();
    SharedPreferences.setMockInitialValues(
        {'lastChecked-de': oldTime.toIso8601String()});
    final prefs = await SharedPreferences.getInstance();

    final ref = ProviderContainer(overrides: [
      languageProvider.overrideWith(() => TestLanguageController()),
      sharedPrefsProvider.overrideWith((ref) => prefs)
    ]);

    expect(await ref.read(backgroundResultProvider.notifier).checkForActivity(),
        false);

    // Now we set the lastChecked timestamp to an invalid value
    await prefs.setString('lastChecked-de', 'invalid');
    expect(await ref.read(backgroundResultProvider.notifier).checkForActivity(),
        false);

    DateTime futureDate = DateTime.now().add(const Duration(days: 1));
    await prefs.setString('lastChecked-de', futureDate.toIso8601String());
    expect(await ref.read(backgroundResultProvider.notifier).checkForActivity(),
        false);

    await prefs.setString('lastChecked-de', DateTime(2023).toIso8601String());
    expect(await ref.read(backgroundResultProvider.notifier).checkForActivity(),
        true);

    expect(ref.read(languageStatusProvider('de')).lastCheckedTimestamp,
        equals(oldTime));
  });
}
