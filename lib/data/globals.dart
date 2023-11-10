import 'package:flutter/material.dart';
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

/// Global key of the ScaffoldMessenger (to simplify snackback handling)
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

/// global constants
class Globals {
  /// Which of these languages are right-to-left? (RTL)
  static const rtlLanguages = ['ar', 'fa'];

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
  /// Must be the main folder name that is inside the zip file we download,
  /// e.g. 'html-en-main'
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
