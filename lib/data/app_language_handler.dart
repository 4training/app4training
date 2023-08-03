import 'package:flutter/services.dart' show rootBundle;

import 'globals.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_language.dart';

Future <dynamic> initAppLanguages() async {

  String source =  await rootBundle.loadString('assets/app_languages.txt');

  // TODO: Get Content from remote repo
  final parsed = jsonDecode(source);
  var list = parsed["languages"];
  for(var element in list) {
    appLanguages.add(AppLanguage.fromJson(element));
  }

  // Check if the user set the app language before, if not, set it to english
  final prefs = await SharedPreferences.getInstance();
  appLanguageCode = (prefs.getString('appLanguage') ?? 'en');

  // If the app language is set to system, check if the local language is supported
  if(appLanguageCode == 'system') {
    bool supported = false;
    for(var element in appLanguages) {
      if(element.languageCode == localLanguageCode) {
        supported = true;
        break;
      }
    }
    // if it is not supported, set it to english
    appLanguageCode = supported ? localLanguageCode : 'en';
  }

}