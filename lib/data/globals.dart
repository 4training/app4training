import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPrefsProvider = MustOverrideProvider<SharedPreferences>();

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

/// global constants
class Globals {
  static const List<String> availableLanguages = [
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

  /// Which page is loaded after startup?
  static const String defaultPage = "God's_Story_(five_fingers)";

  /// Remote Repository
  static const String githubUser = '4training';
  static const String branch = 'main';
  static const String htmlPath = 'html';
  static const String remoteZipUrl = '/archive/refs/heads/$branch.zip';

  /// Url of the zip file for the HTML resources of a language
  static String getRemoteUrl(String languageCode) {
    return 'https://github.com/$githubUser/$htmlPath-$languageCode$remoteZipUrl';
  }

  /// File system path (relative to assets directory)
  /// of the resources in a language
  /// Must be the main folder name that is inside the zip file we download
  static String getLocalPath(String languageCode) {
    return '$htmlPath-$languageCode-$branch';
  }

  /// Url of Github API: have been commits since [timestamp]?
  static String getCommitsSince(String languageCode, DateTime timestamp) {
    assert(timestamp.isUtc);
    return 'https://api.github.com/repos/$githubUser/$htmlPath-$languageCode'
        '/commits?since=${timestamp.toIso8601String()}';
  }
}
