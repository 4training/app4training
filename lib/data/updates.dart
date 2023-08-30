import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:four_training/data/app_language.dart';
import 'package:four_training/data/globals.dart';
import 'package:four_training/l10n/l10n.dart';

/// How often should the app check for updates?
enum CheckFrequency {
  never,
  daily,
  weekly,
  monthly;

  /// Safe conversion method that handles invalid values as well as null
  /// Default value is CheckFrequency.weekly
  static CheckFrequency fromString(String? selection) {
    if (selection == null) return CheckFrequency.weekly;
    try {
      return CheckFrequency.values.byName(selection);
    } on ArgumentError {
      return CheckFrequency.weekly;
    }
  }

  static String getLocalized(BuildContext context, CheckFrequency value) {
    switch (value) {
      case CheckFrequency.never:
        return context.l10n.never;
      case CheckFrequency.daily:
        return context.l10n.daily;
      case CheckFrequency.weekly:
        return context.l10n.weekly;
      case CheckFrequency.monthly:
        return context.l10n.monthly;
    }
  }
}

/// Handling our CheckFrequency and persisting it to the SharedPreferences
class CheckFrequencyNotifier extends Notifier<CheckFrequency> {
  @override
  CheckFrequency build() {
    return CheckFrequency.fromString(
        ref.read(sharedPrefsProvider).getString('checkFrequency'));
  }

  /// Our one function to change our global setting
  void setCheckFrequency(String selection) {
    state = CheckFrequency.fromString(selection);
    ref.read(sharedPrefsProvider).setString('checkFrequency', state.name);
  }
}

final checkFrequencyProvider =
    NotifierProvider<CheckFrequencyNotifier, CheckFrequency>(() {
  return CheckFrequencyNotifier();
});

/// Handle persisting the downloadLanguage setting in the SharedPreferences
class DownloadLanguageNotifier extends FamilyNotifier<bool, String> {
  String _lang = ''; // language code

  @override
  bool build(String arg) {
    _lang = arg;
    // Load the value stored in the SharedPreferences
    bool? value = ref.read(sharedPrefsProvider).getBool('download_$_lang');
    if (value != null) return value;

    // Default: download resources in English + app language
    // (but user may delete even them)
    String appLanguage = ref.read(appLanguageProvider).languageCode;
    if ((_lang == 'en') || (_lang == appLanguage)) {
      ref.read(sharedPrefsProvider).setBool('download_$_lang', true);
      return true;
    }
    return false;
  }

  void setDownload(bool download) {
    state = download;
    ref.read(sharedPrefsProvider).setBool('download_$_lang', download);
  }
}

/// Global state: Should we download specific language and provide it offline?
/// This setting is saved in the SharedPreferences.
///
/// Example: Should we download the German resources?
/// bool downloadDe = ref.watch(downloadLanguageProvider('de'))
/// TODO: This could/should be integrated into [LanguageController]
final downloadLanguageProvider =
    NotifierProvider.family<DownloadLanguageNotifier, bool, String>(() {
  return DownloadLanguageNotifier();
});
