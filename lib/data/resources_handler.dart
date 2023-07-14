import 'package:flutter/material.dart';
import 'package:four_training/data/globals.dart';
import 'package:four_training/data/languages.dart';

/// Make sure we have all the resources downloaded in the languages we want
/// and load the structure
Future<dynamic> initResources() async {
  debugPrint("Starting initResources");

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
