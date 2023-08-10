import 'package:flutter/material.dart';
import 'package:four_training/data/globals.dart';

import '../data/languages.dart';
import 'checkbox_download_language.dart';

/// Here we have all the interactive widgets inside the tablerow with the languages on settings page

IconButton downloadLanguageButton(
    BuildContext ctx, String languageCode, Function callback) {
  return IconButton(
      onPressed: () async {
        Language language = Language(languageCode);
        await language.init();
        languages.add(language);

        callback();
      },
      icon: const Icon(Icons.download));
}

IconButton updateLanguageButton(
    BuildContext ctx, Language? language, Function callback) {
  bool isDisabled;
  if (language == null) {
    isDisabled = true;
  } else {
    isDisabled = language.commitsSinceDownload <= 0;
  }
  return IconButton(
      onPressed: isDisabled
          ? null
          : () async {
              // Delete language
              String languageCode = language!.languageCode;
              language.removeResources();
              languages.remove(language);
              // Download language
              Language newLanguage = Language(languageCode);
              await newLanguage.init();
              languages.add(newLanguage);

              callback();
            },
      icon: const Icon(Icons.refresh));
}

IconButton deleteLanguageButton(
    BuildContext ctx, Language language, Function callback) {
  bool isDisabled = !language.downloaded;

  return IconButton(
    onPressed: isDisabled
        ? null
        : () {
            if (language.languageCode == currentLanguage?.languageCode) {
              showDialog(context: ctx, builder: buildPopupDialogCantDelete);
            } else {
              language.removeResources();
              languages.remove(language);
            }

            callback();
          },
    icon: const Icon(Icons.delete),
    color: Theme.of(ctx).colorScheme.primary,
  );
}

AlertDialog buildPopupDialogCantDelete(BuildContext context) {
  return AlertDialog(
    title: const Text("Warning"),
    content: const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
            "You can't delete the language, that's currently selected. Switch the language and then try again."),
      ],
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text('Close'),
      ),
    ],
  );
}
