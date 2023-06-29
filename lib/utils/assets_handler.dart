import 'package:flutter/material.dart';
import '../data/globals.dart';
import '../data/languages.dart';

Future<dynamic> initAssets() async {
  debugPrint("Starting initAssets");

  for (int i = 0; i < availableLanguages.length; i++) {
    Language language = Language(availableLanguages[i]);
    await language.init();
    languages.add(language);
  }

  // Set the language to the local device language
  // or english, if local language is not available
  currentLanguage = languages.firstWhere(
      (element) => element.languageCode == localLanguage, orElse: () {
    return languages[0];
  });
  debugPrint("Current language set to ${currentLanguage?.languageCode}");

  debugPrint("Finished initAssets");
  return "Done"; // We need to return something so the snapshot "hasData"
}

Future clearAssets() async {
  debugPrint("clearing assets");
  for (var lang in languages) {
    await lang.removeAssets();
  }
  languages.clear();
}
