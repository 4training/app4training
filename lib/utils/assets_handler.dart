import 'package:download_assets/download_assets.dart';
import 'package:flutter/material.dart';
import '../data/globals.dart';
import '../data/languages.dart';

class AssetsHandler {

}

Future<dynamic> initAssets() async {
  debugPrint("initializing");

  for (int i = 0; i < availiableLanguages.length; i++) {

    // for each language we do the following ...
    DownloadAssetsController controller = DownloadAssetsController();
    // Initialize the downloadAssetsController with a custom assetsDir for each language
    String assetsDir = "assets-${availiableLanguages[i]}";
    await controller.init(assetDir: assetsDir);

    // Then we check, if that dir already exists, meaning it is already downloaded
    bool downloaded = await controller.assetsDirAlreadyExists();
    debugPrint("assets (${availiableLanguages[i]}) loaded: $downloaded");

    // Now we store the full path to the language
    String path = controller.assetsDir! + pathStart + availiableLanguages[i] + pathEnd;
    String src = urlStart + availiableLanguages[i] + urlEnd;

    // Add the language to the list
    languages.add(Language(
        lang: availiableLanguages[i],
        src: src,
        path: path,
        htmlData: "",
        downloaded: downloaded,
        controller: controller));

    if (!downloaded) {
      await downloadLanguage(languages[i]);
    }
  }

  currentLanguage = languages[0];
  return "Done"; // We need to return something so the snapshot "hasData"
}

Future downloadLanguage(Language language) async {
  debugPrint("Downloading ${language.lang} ...");

  if (language.downloaded) {
    debugPrint("${language.lang} already downloaded. Continue ...");
    return;
  }

  debugPrint("Start downloading ${language.lang} ...");

  try {
    await language.controller.startDownload(
      assetsUrl: language.src,
      onProgress: (progressValue) {
        if (progressValue < 100) {
          String progress = "Downloading ${language.lang}: ";

          for (int i = 0; i < 100; i++) {
            if (i <= progressValue) {
              progress += "|";
            } else {
              progress += ".";
            }
          }

          debugPrint(progress);
        } else {
          debugPrint("Download completed");
          language.downloaded = true;
        }
      },
    );
  } on DownloadAssetsException catch (e) {
    debugPrint(e.toString());
    language.downloaded = false;
  }
}

Future downloadAllLanguages(List<Language> langs) async {
  debugPrint("downloading all assets");

  for (var lang in langs) {
    downloadLanguage(lang);
  }
}

Future clearAssets() async {
  debugPrint("clearing assets");
  for (var lang in languages)  {

    await lang.controller.clearAssets();
  }

  languages.clear();


}