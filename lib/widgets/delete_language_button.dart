import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:four_training/data/globals.dart';
import 'package:four_training/data/updates.dart';
import 'package:four_training/widgets/cant_delete_alert_dialog.dart';
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
              await lang.deleteResources();
              ref
                  .read(downloadLanguageProvider(languageCode).notifier)
                  .setDownload(false);
            },
      icon: const Icon(Icons.delete),
      color: Theme.of(context).colorScheme.primary,
    );
  }
}
