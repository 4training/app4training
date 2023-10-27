import 'package:app4training/data/globals.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app4training/data/updates.dart';
import '../data/languages.dart';

class DeleteLanguageButton extends ConsumerWidget {
  final String languageCode;
  final bool isDisabled;
  const DeleteLanguageButton(this.languageCode,
      {super.key, this.isDisabled = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    LanguageController lang = ref.read(languageProvider(languageCode).notifier);

    return IconButton(
      onPressed: isDisabled
          ? null
          : () async {
//                showDialog(
//                    context: context, builder: buildPopupDialogCantDelete);
              // snackbar to be shown after the resources are deleted
              final snackBar = SnackBar(
                  content: Text(context.l10n.deletedLanguage(
                      context.l10n.getLanguageName(languageCode))));
              await lang.deleteResources();
              ref
                  .read(downloadLanguageProvider(languageCode).notifier)
                  .setDownload(false);
              ref.watch(scaffoldMessengerProvider).showSnackBar(snackBar);
            },
      icon: const Icon(Icons.delete),
      color: Theme.of(context).colorScheme.primary,
    );
  }
}
