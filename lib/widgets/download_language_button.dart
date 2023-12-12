import 'package:app4training/data/globals.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/languages.dart';

/// Button to download a language. Shows a CircularProgressIndicator while
/// the download is in progress (that's why the class is stateful)
class DownloadLanguageButton extends ConsumerStatefulWidget {
  final String languageCode;

  /// Should the button be highlighted?
  final bool highlight;
  const DownloadLanguageButton(this.languageCode,
      {this.highlight = false, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _DownloadLanguageButtonState();
}

class _DownloadLanguageButtonState
    extends ConsumerState<DownloadLanguageButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    LanguageController lang =
        ref.watch(languageProvider(widget.languageCode).notifier);

    Widget ourWidget = _isLoading
        ? const Center(
            child: SizedBox(
                height: 24, width: 24, child: CircularProgressIndicator()))
        : IconButton(
            onPressed: () async {
              setState(() {
                _isLoading = true;
              });
              // Get l10n now as we can't access context after async gap later
              AppLocalizations l10n = context.l10n;

              bool success = await lang.download();

              ref.watch(scaffoldMessengerProvider).showSnackBar(SnackBar(
                  duration: success
                      ? const Duration(seconds: 1)
                      : const Duration(seconds: 2),
                  content: Text(success
                      ? l10n.downloadedLanguage(
                          l10n.getLanguageName(widget.languageCode))
                      : l10n.downloadError)));
              setState(() {
                _isLoading = false;
              });
            },
            icon: const Icon(Icons.download),
            padding: EdgeInsets.zero);

    return widget.highlight
        ? Container(
            decoration: BoxDecoration(
                color: Theme.of(context).highlightColor,
                borderRadius: BorderRadius.circular(8.0)),
            child: ourWidget)
        : ourWidget;
  }
}

/// Button to download all languages. Shows a CircularProgressIndicator while
/// the download is in progress (that's why the class is stateful)
class DownloadAllLanguagesButton extends ConsumerStatefulWidget {
  const DownloadAllLanguagesButton({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _DownloadAllLanguagesButtonState();
}

class _DownloadAllLanguagesButtonState
    extends ConsumerState<DownloadAllLanguagesButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
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
              int countDownloads = 0;
              int countErrors = 0;
              String lastLanguage = '';
              for (var languageCode in ref.read(availableLanguagesProvider)) {
                if (!ref.watch(languageProvider(languageCode)).downloaded) {
                  if (await ref
                      .read(languageProvider(languageCode).notifier)
                      .download()) {
                    countDownloads++;
                    lastLanguage = languageCode;
                  } else {
                    countErrors++;
                  }
                }
              }
              if (countDownloads > 0) {
                // Show info message in snackbar
                String text = (countDownloads == 1)
                    ? l10n
                        .downloadedLanguage(l10n.getLanguageName(lastLanguage))
                    : l10n.downloadedNLanguages(countDownloads, countErrors);
                final snackBar = SnackBar(content: Text(text));
                ref.watch(scaffoldMessengerProvider).showSnackBar(snackBar);
              } else if (countErrors > 0) {
                ref
                    .watch(scaffoldMessengerProvider)
                    .showSnackBar(SnackBar(content: Text(l10n.downloadError)));
              }
              setState(() {
                _isLoading = false;
              });
            },
            icon: const Icon(Icons.download),
            padding: EdgeInsets.zero);
  }
}
