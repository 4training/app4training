import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'globals.dart';

/// Holds the current app language: available through [appLanguageProvider]
/// This state is immutable - if the app language changes, a new AppLanguage
/// object is created
@immutable
class AppLanguage {
  final bool isSystemDefault;
  final String languageCode;
  const AppLanguage(this.isSystemDefault, this.languageCode);

  Locale get locale => Locale(languageCode);

  @override
  String toString() {
    return isSystemDefault ? 'system' : languageCode;
  }

  /// [str] can be a language code ('en', 'de', ...) or 'system'
  /// In case of 'system': Use the [defaultLangCode]
  static AppLanguage fromString(String str, String defaultLangCode) {
    if (!availableAppLanguages.keys.contains(str)) str = 'system';
    bool isSystemLanguage = str == 'system';

    String languageCode = str;
    if (isSystemLanguage) {
      languageCode = defaultLangCode;
    }
    if ((languageCode == 'system') ||
        !availableAppLanguages.keys.contains(languageCode)) {
      // English is default in case we can't make sense of our parameters
      languageCode = 'en';
    }
    return AppLanguage(isSystemLanguage, languageCode);
  }

  /// The languages available for the whole app:
  /// identifier (language code) => description shown (autonym of language)
  /// TODO get this from supportedLocales?
  static const Map<String, String> availableAppLanguages = {
    'system': 'System default',
    'en': 'English (en)',
    'de': 'Deutsch (de)'
  };
}

/// This class also takes care of persistance and reads/writes
/// the currently selected app language into the SharedPreferences
class AppLanguageController extends Notifier<AppLanguage> {
  @override
  AppLanguage build() {
    // Load the value stored in the SharedPreferences
    String storedPref =
        ref.read(sharedPrefsProvider).getString('appLanguage') ?? 'system';
    return AppLanguage.fromString(storedPref, LocaleWrapper.languageCode);
  }

  /// [selection] can be a language code ('en', 'de', ...) or 'system'
  void setLocale(String selection) {
    state = AppLanguage.fromString(selection, LocaleWrapper.languageCode);
    ref.read(sharedPrefsProvider).setString('appLanguage', state.toString());
  }

  /// Save the current appLanguage in the SharedPreferences
  void persistNow() {
    ref.read(sharedPrefsProvider).setString('appLanguage', state.toString());
  }
}

final appLanguageProvider =
    NotifierProvider<AppLanguageController, AppLanguage>(() {
  return AppLanguageController();
});

/// wrapper class around `Platform.localeName`:
/// - provides the language code (just 'en' instead of 'en_US' e.g.)
/// - for better testability
///
/// Remark: This doesn't change while the app is running,
/// even if the user changes their devices' language configuration
class LocaleWrapper {
  static String get languageCode {
    int index = Platform.localeName.indexOf('_');
    return Platform.localeName.substring(0, index < 0 ? null : index);
  }
}
