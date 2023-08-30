import 'package:flutter/material.dart';
import 'package:four_training/data/globals.dart';
import '../data/languages.dart';

class UpdateLanguageButton extends StatefulWidget {
  const UpdateLanguageButton(
      {Key? key, required this.language, required this.callback})
      : super(key: key);

  final Language language;
  final Function callback;

  @override
  State<UpdateLanguageButton> createState() => _UpdateLanguageButtonState();
}

class _UpdateLanguageButtonState extends State<UpdateLanguageButton> {
  @override
  Widget build(BuildContext context) {
    return IconButton(
        onPressed: null,
        /* TODO () async {
          // Delete language
          String languageCode = widget.language.languageCode;
          await widget.language.removeResources();
          if(mounted) context.global.languages.remove(widget.language);
          // Download language
          Language newLanguage = Language(languageCode);
          await newLanguage.init();
          if(mounted) context.global.languages.add(newLanguage);
          widget.callback();
        },*/
        icon: const Icon(Icons.refresh));
  }
}
