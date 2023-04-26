import 'package:four_training/data/languages.dart';

List<Language> languages = [];
Language? currentLanguage;
int currentIndex = 0;
final List<String> availableLanguages = ["en", "de"];

const String urlStart = "https://github.com/holybiber/test-html-";
const String urlEnd = "/archive/refs/heads/main.zip";
const String pathStart = "/test-html-";
const String pathEnd = "-main";

const String latestCommitsStart = "https://api.github.com/repos/holybiber/test-html-";
const String latestCommitsEnd = "/commits?since=";
bool newCommitsAvailable = false;