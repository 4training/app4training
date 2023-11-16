import 'package:app4training/data/app_language.dart';
import 'package:app4training/data/globals.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/languages.dart';

/// Button to delete one language
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
                ref.watch(scaffoldMessengerProvider).showSnackBar(snackBar);
              },
        icon: const Icon(Icons.delete),
        color: Theme.of(context).colorScheme.primary,
        padding: EdgeInsets.zero);
  }
}

/// Button to delete all languages
/// (except English and the currently selected app language)
class DeleteAllLanguagesButton extends ConsumerWidget {
  const DeleteAllLanguagesButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
        onPressed: () async {
          // snackbar to be shown after the resources are deleted
          // Get l10n now as we can't access context after async gap later
          AppLocalizations l10n = context.l10n;
          int countDeleted = 0;
          String lastLanguage = '';
          for (var languageCode in ref.read(availableLanguagesProvider)) {
            // Delete all languages except English and the current app language
            if ((languageCode == 'en') ||
                (languageCode == ref.read(appLanguageProvider).languageCode)) {
              continue;
            }
            if (ref.watch(languageProvider(languageCode)).downloaded) {
              await ref
                  .read(languageProvider(languageCode).notifier)
                  .deleteResources();
              countDeleted++;
              lastLanguage = languageCode;
            }
          }

          if (countDeleted > 0) {
            // Show info message in snackbar
            String text = (countDeleted == 1)
                ? l10n.deletedLanguage(l10n.getLanguageName(lastLanguage))
                : l10n.deletedNLanguages(countDeleted);
            final snackBar = SnackBar(content: Text(text));
            ref.watch(scaffoldMessengerProvider).showSnackBar(snackBar);
          }
        },
        icon: const Icon(Icons.delete),
        color: Theme.of(context).colorScheme.primary,
        padding: EdgeInsets.zero);
  }
}
