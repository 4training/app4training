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
  static const List<String> availableLanguages = ["en", "de"];

  /// Which page is loaded after startup?
  static const String defaultPage = "God's_Story_(five_fingers)";

  /// Remote Repository
  static const String urlStart = "https://github.com/holybiber/test-html-";
  static const String urlEnd = "/archive/refs/heads/main.zip";
  static const String pathStart = "/test-html-";
  static const String pathEnd = "-main";

  static const String latestCommitsStart =
      "https://api.github.com/repos/holybiber/test-html-";
  static const String latestCommitsEnd = "/commits?since=";
}
