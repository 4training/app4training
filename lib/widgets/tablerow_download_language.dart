import 'package:flutter/material.dart';

import '../data/languages.dart';
import 'checkbox_download_language.dart';

TableRow tableRowDownloadLanguage(Language language, BuildContext ctx) {
  IconData upToDate = language.commitsSinceDownload > 0 ? Icons.refresh : Icons.check;

  return TableRow(children: [
    Container(
        height: 32,
        alignment: Alignment.center,
        child: CheckBoxDownloadLanguage(language: language)),
    Container(
        height: 32,
        alignment: Alignment.centerLeft,
        child: Text(language.languageCode.toUpperCase(),
            style: Theme.of(ctx).textTheme.bodyMedium)),
    Container(
        height: 32,
        alignment: Alignment.centerLeft,
        child: IconButton(onPressed: () {  }, icon:  Icon(upToDate),)),
    Container(
        height: 32,
        alignment: Alignment.centerLeft,
        child: IconButton(onPressed: () {  }, icon: const Icon(Icons.delete), color: Theme.of(ctx).colorScheme.primary,)),
  ]);
}
