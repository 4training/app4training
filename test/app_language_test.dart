import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:app4training/data/app_language.dart';

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

    // TODO: Test persistance: setLocale() and persistNow()
  });
}
