import 'dart:io';

import 'package:app4training/data/globals.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app4training/data/app_language.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// For setting the app language in tests
///
/// When testing with different locales, always override
/// appLanguageProvider with this class and then pumpWidget() with
/// MaterialApp(locale: ref.watch(appLanguageProvider).locale)
/// to avoid any inconsistencies between app locale and appLanguageProvider
class TestAppLanguage extends AppLanguageController {
  final String _languageCode;
  TestAppLanguage(this._languageCode);

  @override
  AppLanguage build() {
    return AppLanguage(true, _languageCode);
  }

  @override
  void setLocale(String selection) {
    state = AppLanguage.fromString(selection, _languageCode);
  }

  @override
  void persistNow() {}
}

void main() {
  test('Test LocaleWrapper', () {
    expect(Platform.localeName, startsWith(LocaleWrapper.languageCode));
    expect(LocaleWrapper.languageCode.length, greaterThanOrEqualTo(2));
  });
  group('Test AppLanguage class', () {
    test('Test AppLanguage.fromString()', () {
      AppLanguage appLanguage = AppLanguage.fromString('de', 'en');
      expect(appLanguage.isSystemDefault, false);
      expect(appLanguage.languageCode, equals('de'));

      appLanguage = AppLanguage.fromString('invalid', 'de');
      expect(appLanguage.isSystemDefault, true);
      expect(appLanguage.languageCode, equals('de'));

      appLanguage = AppLanguage.fromString('system', 'de');
      expect(appLanguage.isSystemDefault, true);
      expect(appLanguage.languageCode, equals('de'));

      appLanguage = AppLanguage.fromString('system', 'invalid');
      expect(appLanguage.isSystemDefault, true);
      expect(appLanguage.languageCode, equals('en'));

      // Edge cases
      appLanguage = AppLanguage.fromString('invalid', 'system');
      expect(appLanguage.isSystemDefault, true);
      expect(appLanguage.languageCode, equals('en'));

      appLanguage = AppLanguage.fromString('invalid', 'invalid');
      expect(appLanguage.isSystemDefault, true);
      expect(appLanguage.languageCode, equals('en'));
    });
    test('Test AppLanguage.toString()', () {
      expect(const AppLanguage(true, 'de').toString(), equals('system'));
      expect(const AppLanguage(false, 'de').toString(), equals('de'));
    });

    test('Test appLanguage persistance: getting and setting', () async {
      SharedPreferences.setMockInitialValues({'appLanguage': 'de'});
      final prefs = await SharedPreferences.getInstance();
      final ref = ProviderContainer(
          overrides: [sharedPrefsProvider.overrideWithValue(prefs)]);

      expect(prefs.getString('appLanguage'), equals('de'));
      expect(ref.read(appLanguageProvider).languageCode, equals('de'));
      ref.read(appLanguageProvider.notifier).setLocale('en');
      expect(ref.read(appLanguageProvider).languageCode, equals('en'));
      expect(prefs.getString('appLanguage'), equals('en'));

      ref.read(appLanguageProvider.notifier).setLocale('system');
      expect(ref.read(appLanguageProvider).languageCode, equals('en'));
      expect(ref.read(appLanguageProvider).isSystemDefault, true);
      expect(prefs.getString('appLanguage'), equals('system'));
    });

    test('Test appLanguage persistNow()', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final ref = ProviderContainer(
          overrides: [sharedPrefsProvider.overrideWithValue(prefs)]);

      expect(prefs.getString('appLanguage'), isNull);
      expect(ref.read(appLanguageProvider).isSystemDefault, true);
      ref.read(appLanguageProvider.notifier).persistNow();
      expect(prefs.getString('appLanguage'), equals('system'));

      ref.read(appLanguageProvider.notifier).setLocale('de');
      ref.read(appLanguageProvider.notifier).persistNow();
      expect(ref.read(appLanguageProvider).languageCode, 'de');
      expect(prefs.getString('appLanguage'), equals('de'));
    });
  });

  test('Test TestAppLanguage class', () {
    final ref = ProviderContainer(overrides: [
      appLanguageProvider.overrideWith(() => TestAppLanguage('de'))
    ]);
    expect(ref.read(appLanguageProvider).languageCode, 'de');
    ref.read(appLanguageProvider.notifier).setLocale('en');
    expect(ref.read(appLanguageProvider).languageCode, 'en');
    ref.read(appLanguageProvider.notifier).setLocale('system');
    expect(ref.read(appLanguageProvider).languageCode, 'de');
    ref.read(appLanguageProvider.notifier).persistNow();
    expect(ref.read(appLanguageProvider).languageCode, 'de');
  });
}
