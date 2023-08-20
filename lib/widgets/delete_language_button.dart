import 'package:flutter/material.dart';
import 'package:four_training/data/globals.dart';
import 'package:four_training/widgets/cant_delete_alert_dialog.dart';
import '../data/languages.dart';

class DeleteLanguageButton extends StatefulWidget {
  const DeleteLanguageButton(
      {Key? key, required this.language, required this.callback})
      : super(key: key);

  final Language language;
  final Function callback;

  @override
  State<DeleteLanguageButton> createState() => _DeleteLanguageButtonState();
}

class _DeleteLanguageButtonState extends State<DeleteLanguageButton> {
  late bool isDisabled;

  @override
  Widget build(BuildContext context) {
    isDisabled = !widget.language.downloaded;

    return IconButton(
      onPressed: isDisabled
          ? null
          : () async {
              if (widget.language.languageCode ==
                  context.global.currentLanguage?.languageCode) {
                showDialog(
                    context: context, builder: buildPopupDialogCantDelete);
              } else {
                await widget.language.removeResources();
                if (mounted) context.global.languages.remove(widget.language);
              }
              widget.callback();
            },
      icon: const Icon(Icons.delete),
      color: Theme.of(context).colorScheme.primary,
    );
  }
}
