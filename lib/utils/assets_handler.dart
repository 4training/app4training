import 'dart:io';
import 'package:flutter/material.dart';
import '../data/globals.dart';
import '../data/languages.dart';

class AssetsHandler {}
// API Zugriff auf letzten Commit
// https://api.github.com/repos/holybiber/test-html-de/commits?since=2022-04-09T09:23:14Z

Future<dynamic> initAssets() async {
  debugPrint("Starting initAssets");

  for (int i = 0; i < availableLanguages.length; i++) {
    Language language = Language(availableLanguages[i]);
    await language.init();
    // Add the language to the list
    languages.add(language);

  }
  currentLanguage = languages[1];
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
  for (var lang in languages)  {

    await lang.controller.clearAssets();
  }

  languages.clear(); // TODO

}

Future<dynamic> displayAssets() async {
  debugPrint( "displaying assets $currentLanguage, all Pages");

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