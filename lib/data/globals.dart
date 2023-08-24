import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:four_training/data/languages.dart';
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

/// Holds our global state
// TODO: Clean up the numerous issues of this class
// - make this class immutable
// - think through which widgets need to be updated on which changes
//   and implement Notifiers for necessary rebuilds
// - handle persistence here
class GlobalData extends InheritedWidget {
  GlobalData({super.key, required super.child});

  /// Content Languages
  List<Language> languages = [];
  Language? currentLanguage;
  static const List<String> availableLanguages = ["en", "de"];

  /// The currently selected page (without language code)
  String currentPage = "";

  /// Local Language of the device
  // TODO this is not consistently set to the currently active language...
  String localLanguageCode = "";

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
  bool newCommitsAvailable = false;

  /// Make sure we have all the resources downloaded in the languages we want
  /// and load the structure
  Future<dynamic> initResources() async {
    debugPrint("Starting initResources");

    for (int i = 0; i < availableLanguages.length; i++) {
      Language language = Language(availableLanguages[i]);
      await language.init();
      if (language.commitsSinceDownload > 0) {
        newCommitsAvailable = true;
      }

      languages.add(language);
    }

    // Set the language to the local device language
    // or english, if local language is not available
    currentLanguage = languages.firstWhere(
        (element) => element.languageCode == localLanguageCode, orElse: () {
      return languages[0];
    });

    debugPrint("Current language set to ${currentLanguage?.languageCode}");

    debugPrint("Finished initResources");
    return "Done"; // We need to return something so the snapshot "hasData"
  }

  Future clearResources() async {
    debugPrint("clearing resources");
    for (var lang in languages) {
      await lang.removeResources();
    }
    languages.clear();
  }

  int getResourcesSizeInKB() {
    int size = 0;
    for (var lang in languages) {
      size += lang.sizeInKB;
    }
    return size;
  }

  static GlobalData of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GlobalData>()!;
  }

  @override
  bool updateShouldNotify(covariant GlobalData oldWidget) {
    return false;
  }
}

/// Simplify working with GlobalData:
/// If we have a BuildContext context somewhere, we can now just say
/// context.global.
extension GlobalExt on BuildContext {
  GlobalData get global => GlobalData.of(this);
}
