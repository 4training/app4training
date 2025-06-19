import 'package:app4training/data/globals.dart';
import 'package:app4training/l10n/generated/app_localizations.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app4training/data/updates.dart';
import '../data/languages.dart';

/// Button to update a language. Shows a CircularProgressIndicator while
/// the download is in progress (that's why the class is stateful)
class UpdateLanguageButton extends ConsumerStatefulWidget {
  final String languageCode;
  const UpdateLanguageButton(this.languageCode, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _UpdateLanguageButtonState();
}

class _UpdateLanguageButtonState extends ConsumerState<UpdateLanguageButton> {
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    LanguageController lang =
        ref.read(languageProvider(widget.languageCode).notifier);
    return _isUpdating
        ? const Center(
            child: SizedBox(
                height: 24, width: 24, child: CircularProgressIndicator()))
        : IconButton(
            onPressed: () async {
              setState(() {
                _isUpdating = true;
              });
              // Get l10n now as we can't access context after async gap later
              AppLocalizations l10n = context.l10n;

              bool success = await lang.download(force: true);

              ref.watch(scaffoldMessengerProvider).showSnackBar(SnackBar(
                  content: Text(success
                      ? l10n.updatedLanguage(
                          l10n.getLanguageName(widget.languageCode))
                      : l10n.updateError)));

              setState(() {
                _isUpdating = false;
              });
            },
            icon: const Icon(Icons.refresh),
            padding: EdgeInsets.zero);
  }
}

/// Button to update all languages (which have an update available).
/// Shows a CircularProgressIndicator while the download is in progress.
class UpdateAllLanguagesButton extends ConsumerStatefulWidget {
  const UpdateAllLanguagesButton({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _UpdateAllLanguagesButtonState();
}

class _UpdateAllLanguagesButtonState
    extends ConsumerState<UpdateAllLanguagesButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // Don't show the button if there are no updates available
    if (!ref.watch(updatesAvailableProvider)) return const Text("");

    return _isLoading
        ? const Center(
            child: SizedBox(
                height: 24, width: 24, child: CircularProgressIndicator()))
        : IconButton(
            onPressed: () async {
              setState(() {
                _isLoading = true;
              });
              // Get l10n now as we can't access context after async gap later
              final l10n = context.l10n;
              int countUpdates = 0;
              int countErrors = 0;
              String lastLanguage = '';
              for (var languageCode in ref.read(availableLanguagesProvider)) {
                final status = ref.read(languageStatusProvider(languageCode));
                if (status.updatesAvailable &&
                    ref.read(languageProvider(languageCode)).downloaded) {
                  if (await ref
                      .read(languageProvider(languageCode).notifier)
                      .download(force: true)) {
                    countUpdates++;
                    lastLanguage = languageCode;
                  } else {
                    countErrors++;
                  }
                }
              }
              if (countUpdates > 0) {
                // Show info message in snackbar
                String text = (countUpdates == 1)
                    ? l10n.updatedLanguage(l10n.getLanguageName(lastLanguage))
                    : l10n.updatedNLanguages(countUpdates, countErrors);
                final snackBar = SnackBar(content: Text(text));
                ref.watch(scaffoldMessengerProvider).showSnackBar(snackBar);
              } else if (countErrors > 0) {
                ref
                    .watch(scaffoldMessengerProvider)
                    .showSnackBar(SnackBar(content: Text(l10n.updateError)));
              }
              setState(() {
                _isLoading = false;
              });
            },
            icon: const Icon(Icons.refresh),
            padding: EdgeInsets.zero);
  }
}
