import 'package:four_training/data/languages.dart';

List<Language> languages = [];
Language? currentLanguage;
int currentIndex = 0;
final List<String> availiableLanguages = ["en", "de"];

const String urlStart = "https://github.com/holybiber/test-html-";
const String urlEnd = "/archive/refs/heads/main.zip";
const String pathStart = "/test-html-";
const String pathEnd = "-main";
