import 'package:app4training/data/globals.dart';
import 'package:app4training/data/updates.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'updates_test.dart';

/// Build a container where 'de' has updates available (or not) and the
/// AutomaticUpdates setting is [automaticUpdates].
Future<ProviderContainer> makeRef({
  required String automaticUpdates,
  bool hasUpdates = true,
}) async {
  SharedPreferences.setMockInitialValues({
    'automaticUpdates': automaticUpdates,
  });
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      languageStatusProvider.overrideWith2(
        (langCode) =>
            TestLanguageStatus(langWithUpdates: hasUpdates ? ['de'] : []),
      ),
    ],
  );
}

void main() {
  test('True only for requireConfirmation with updates available', () async {
    final ref = await makeRef(automaticUpdates: 'requireConfirmation');
    expect(ref.read(updatesNeedConfirmationProvider), true);
  });

  test('False for requireConfirmation when no updates available', () async {
    final ref = await makeRef(
      automaticUpdates: 'requireConfirmation',
      hasUpdates: false,
    );
    expect(ref.read(updatesNeedConfirmationProvider), false);
  });

  test('False for other AutomaticUpdates modes even with updates', () async {
    for (final mode in ['never', 'onlyOnWifi', 'yesAlways']) {
      final ref = await makeRef(automaticUpdates: mode);
      expect(
        ref.read(updatesNeedConfirmationProvider),
        false,
        reason: 'should be false for $mode',
      );
    }
  });
}
