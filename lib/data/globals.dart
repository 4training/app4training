import 'package:four_training/data/languages.dart';
import 'package:four_training/data/resources_handler.dart';
import 'app_language.dart';
import 'app_language_handler.dart';

/// Content Languages
List<Language> languages = [];
Language? currentLanguage;
final List<String> availableLanguages = ["en", "de"];

/// App Languages (settings)
// TODO get the list from the repository - maybe create applanguage class
List<String> availableAppLanguages = ["system", "en", "de"];
List<AppLanguage> appLanguages = [];
// TODO Do we want this variable or only use the value stored in prefs? How do we handle prefs? Load on startup?
String appLanguageCode = "en";

/// The currently selected page (without language code)
String currentPage = "";

/// Local Language of the device
// TODO this is not consistently set to the currently active language...
String localLanguageCode = "";

/// Which page is loaded after startup?
const String defaultPage = "God's_Story_(five_fingers)";

/// Remote Repository
const String urlStart = "https://github.com/holybiber/test-html-";
const String urlEnd = "/archive/refs/heads/main.zip";
const String pathStart = "/test-html-";
const String pathEnd = "-main";

const String latestCommitsStart =
    "https://api.github.com/repos/holybiber/test-html-";
const String latestCommitsEnd = "/commits?since=";
bool newCommitsAvailable = false;

Future<dynamic> globalInit() async {
  await initResources();
  await initAppLanguages();
  return "Done"; // We need to return something so the snapshot "hasData"
}
