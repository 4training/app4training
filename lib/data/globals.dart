import 'package:four_training/data/languages.dart';

List<Language> languages = [];
Language? currentLanguage;
// The currently selected page (without language code)
String currentPage = "";
final List<String> availableLanguages = ["en", "de"];
// TODO this is not consistently set to the currently active language...
String localLanguage = "";

/// Which page is loaded after startup?
const String defaultPage = "God's_Story_(five_fingers)";

const String urlStart = "https://github.com/holybiber/test-html-";
const String urlEnd = "/archive/refs/heads/main.zip";
const String pathStart = "/test-html-";
const String pathEnd = "-main";

const String latestCommitsStart =
    "https://api.github.com/repos/holybiber/test-html-";
const String latestCommitsEnd = "/commits?since=";
bool newCommitsAvailable = false;
