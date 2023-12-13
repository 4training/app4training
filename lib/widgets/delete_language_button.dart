import 'package:app4training/data/app_language.dart';
import 'package:app4training/data/globals.dart';
import 'package:app4training/design/theme.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/languages.dart';

/// Button to delete one language
class DeleteLanguageButton extends ConsumerWidget {
  final String languageCode;
  const DeleteLanguageButton(this.languageCode, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // discourage deletion the currently selected app language:
    // - grey the icon out
    // - if a user still clicks it, let him confirm the deletion first
    final appLang = ref.watch(appLanguageProvider).languageCode;
    bool isDiscouraged = (languageCode == appLang);

    LanguageController lang = ref.read(languageProvider(languageCode).notifier);

    return IconButton(
        onPressed: () async {
          // snackbar to be shown after the resources are deleted
          final snackBar = SnackBar(
            content: Text(context.l10n
                .deletedLanguage(context.l10n.getLanguageName(languageCode))),
            duration: const Duration(seconds: 1),
          );
          if (isDiscouraged) {
            bool result = await showDialog(
                context: context,
                builder: (context) {
                  return const ConfirmDeletionDialog();
                });
            if (!result) return;
          }
          await lang.deleteResources();
          ref.watch(scaffoldMessengerProvider).showSnackBar(snackBar);
        },
        icon: const Icon(Icons.delete),
        color: isDiscouraged
            ? greyedOutColor
            : Theme.of(context).colorScheme.primary,
        padding: EdgeInsets.zero);
  }
}

/// Button to delete all languages
/// (except the currently selected app language)
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
            // Delete all languages except the current app language
            if (languageCode == ref.read(appLanguageProvider).languageCode) {
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

/// Shows a dialog when a user tries to delete the app language:
/// Are you really sure?
class ConfirmDeletionDialog extends StatelessWidget {
  const ConfirmDeletionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: Text(context.l10n.warning),
        content: Text(context.l10n.warnBeforeDelete),
        actions: <Widget>[
          TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text(context.l10n.cancel)),
          TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(context.l10n.delete))
        ]);
  }
}
