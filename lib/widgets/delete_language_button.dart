import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:four_training/data/globals.dart';
import 'package:four_training/widgets/cant_delete_alert_dialog.dart';
import '../data/languages.dart';

class DeleteLanguageButton extends ConsumerWidget {
  const DeleteLanguageButton({Key? key, required this.languageCode})
      : super(key: key);

  final String languageCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
//    Language language = ref.read(languageProvider);

    return IconButton(
      onPressed: null,
/* TODO     isDisabled
          ? null
          : () async {
              if (language.languageCode ==
                  context.global.currentLanguage?.languageCode) {
                showDialog(
                    context: context, builder: buildPopupDialogCantDelete);
              } else {
                await language.removeResources();
                if (mounted) context.global.languages.remove(language);
              }
              widget.callback();
            },*/
      icon: const Icon(Icons.delete),
      color: Theme.of(context).colorScheme.primary,
    );
  }
}
