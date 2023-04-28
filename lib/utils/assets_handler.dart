import 'dart:io';
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
  currentLanguage = languages
      .firstWhere((element) => element.lang == localLanguage, orElse: () {
    return languages[0];
  });
  debugPrint("Current language set to ${currentLanguage?.lang}");

  debugPrint("Finished initAssets");
  return "Done"; // We need to return something so the snapshot "hasData"
}

Future downloadAllLanguages(List<Language> langs) async {
  debugPrint("downloading all languages");

  for (var lang in langs) {
    lang.download();
  }
}

Future clearAssets() async {
  debugPrint("clearing assets");
  for (var lang in languages) {
    await lang.controller.clearAssets();
  }
  languages.clear();
}

Future<dynamic> displayAssets() async {
  debugPrint("displaying assets $currentLanguage, all Pages");

  List<String> htmlData = [];

  if (currentLanguage == null) {
    return Future.error("Language is null");
  }

  try {
    debugPrint(currentLanguage!.path);
    var dir = Directory(currentLanguage!.path);

    await for (var file in dir.list(recursive: false, followLinks: false)) {
      if (file.statSync().type == FileSystemEntityType.file) {
        htmlData.add(await File(file.path).readAsString());
      }
    }

    debugPrint("Finished creating html data");
    return htmlData;
  } catch (e) {
    String msg = e.toString();
    debugPrint("Error creating html data. $msg");
    return Future.error(msg);
  }
}
