import 'package:app4training/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPrefsProvider = MustOverrideProvider<SharedPreferences>();
final packageInfoProvider = MustOverrideProvider<PackageInfo>();

/// ignore: non_constant_identifier_names
Provider<T> MustOverrideProvider<T>() {
  return Provider<T>(
    (_) => throw ProviderNotOverriddenException(),
  );
}

class ProviderNotOverriddenException implements Exception {
  @override
  String toString() {
    return 'The value for this provider must be set by an override on ProviderScope';
  }
}

/// Global key of the ScaffoldMessenger (to simplify snackbar handling)
final scaffoldMessengerKeyProvider = Provider((ref) {
  return GlobalKey<ScaffoldMessengerState>();
});

/// Provider to access the ScaffoldMessenger from everywhere to show a snackbar
/// Usage: ref.watch(scaffoldMessengerProvider).showSnackbar()
///
/// This is better than using ScaffoldMessenger.of(context).showSnackbar()
/// as we don't need a BuildContext (which is not available in async callbacks)
final scaffoldMessengerProvider = Provider((ref) {
  return ref.watch(scaffoldMessengerKeyProvider).currentState!;
});

const int countAvailableLanguages = 34;

final availableLanguagesProvider = Provider<List<String>>((ref) {
  return [
    'tr',
    'zh',
    'vi',
    'ro',
    'ky',
    'pl',
    'id',
    'xh',
    'uz',
    'af',
    'ta',
    'sr',
    'ms',
    'az',
    'ti',
    'sw',
    'nb',
    'ku',
    'sv',
    'ml',
    'hi',
    'lg',
    'kn',
    'it',
    'cs',
    'fa',
    'ar',
    'ru',
    'nl',
    'fr',
    'es',
    'sq',
    'en',
    'de'
  ];
});

/// Should the app do automatic updates?
/// Default: yes but only when in Wifi
enum AutomaticUpdates {
  never,
  requireConfirmation,
  onlyOnWifi,
  yesAlways;

  /// Safe conversion method that handles invalid values as well as null
  /// Default value is AutomaticUpdates.yesOnWifi
  static AutomaticUpdates fromString(String? selection) {
    if (selection == null) return AutomaticUpdates.onlyOnWifi;
    try {
      return AutomaticUpdates.values.byName(selection);
    } on ArgumentError {
      return AutomaticUpdates.onlyOnWifi;
    }
  }

  static String getLocalized(BuildContext context, AutomaticUpdates value) {
    switch (value) {
      case AutomaticUpdates.never:
        return context.l10n.never;
      case AutomaticUpdates.requireConfirmation:
        return context.l10n.requireConfirmation;
      case AutomaticUpdates.onlyOnWifi:
        return context.l10n.onlyOnWifi;
      case AutomaticUpdates.yesAlways:
        return context.l10n.yesAlways;
    }
  }
}

/// Handling our ConfirmDataUsage and persisting it to the SharedPreferences
class AutomaticUpdatesNotifier extends Notifier<AutomaticUpdates> {
  @override
  AutomaticUpdates build() {
    return AutomaticUpdates.fromString(
        ref.read(sharedPrefsProvider).getString('automaticUpdates'));
  }

  /// Our one function to change our global setting
  void setAutomaticUpdates(String? selection) {
    state = AutomaticUpdates.fromString(selection);
    ref.read(sharedPrefsProvider).setString('automaticUpdates', state.name);
  }

  /// Save the current setting in SharedPreferences
  void persistNow() {
    ref.read(sharedPrefsProvider).setString('automaticUpdates', state.name);
  }
}

final automaticUpdatesProvider =
    NotifierProvider<AutomaticUpdatesNotifier, AutomaticUpdates>(() {
  return AutomaticUpdatesNotifier();
});

/// global constants
class Globals {
  static const appTitle = '4training';

  /// Which of these languages are right-to-left? (RTL)
  static const rtlLanguages = ['ar', 'fa'];

  /// Remote Repository
  static const String githubUser = '4training';
  static const String branch = 'main';
  static const String htmlPath = 'html';
  static const String remoteZipUrl = '/archive/refs/heads/$branch.zip';

  /// Url of the zip file for the HTML resources of a language
  static String getRemoteUrl(String languageCode) {
    return 'https://github.com/$githubUser/$htmlPath-$languageCode$remoteZipUrl';
  }

  /// Folder name of the resources of a language. Example: html-en-main
  ///
  /// Must be the main folder name that is inside the zip file we download.
  static String getResourcesDir(String languageCode) {
    return '$htmlPath-$languageCode-$branch';
  }

  /// Folder name of the assets dir of a language
  static String getAssetsDir(String languageCode) {
    return 'assets-$languageCode';
  }

  /// URL of Github API to query whether there are new commits since [timestamp]
  /// Documentation: https://docs.github.com/en/rest/commits/commits
  static String getCommitsSince(String languageCode, DateTime timestamp) {
    assert(timestamp.isUtc);
    return 'https://api.github.com/repos/$githubUser/$htmlPath-$languageCode'
        '/commits?since=${timestamp.toIso8601String()}';
  }
}
