import 'package:flutter/material.dart';
import 'package:four_training/data/globals.dart';
import '../data/languages.dart';

class DownloadLanguageButton extends StatefulWidget {
  const DownloadLanguageButton(
      {Key? key, required this.languageCode, required this.callback})
      : super(key: key);

  final String languageCode;
  final Function callback;

  @override
  State<DownloadLanguageButton> createState() => _DownloadLanguageButtonState();
}

class _DownloadLanguageButtonState extends State<DownloadLanguageButton> {
  @override
  Widget build(BuildContext context) {
    return IconButton(
        onPressed: () async {
          Language language = Language(widget.languageCode);
          await language.init();
          if (mounted) context.global.languages.add(language);
          widget.callback();
        },
        icon: const Icon(Icons.download));
  }
}
