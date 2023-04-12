import 'package:download_assets/download_assets.dart';

class Language {

  final String lang;
  final String src;
  final String path;
  String htmlData;
  bool downloaded;
  final DownloadAssetsController controller;

  Language({
    required this.lang,
    required this.src,
    required this.path,
    required this.htmlData,
    required this.downloaded,
    required this.controller,
});


}

List<Language> languages = [



];