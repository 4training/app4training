import 'package:app4training/data/bulk_language_download.dart';
import 'package:app4training/data/globals.dart';
import 'package:app4training/design/theme.dart';
import 'package:app4training/l10n/generated/app_localizations.dart';
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
  const DownloadLanguageButton(
    this.languageCode, {
    this.highlight = false,
    super.key,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _DownloadLanguageButtonState();
}

class _DownloadLanguageButtonState
    extends ConsumerState<DownloadLanguageButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    LanguageController lang = ref.watch(
      languageProvider(widget.languageCode).notifier,
    );

    Widget ourWidget =
        _isLoading
            ? const Center(
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(),
              ),
            )
            : IconButton(
              onPressed: () async {
                setState(() {
                  _isLoading = true;
                });
                // Get l10n now as we can't access context after async gap later
                AppLocalizations l10n = context.l10n;

                bool success = await lang.download();

                ref
                    .watch(scaffoldMessengerProvider)
                    .showSnackBar(
                      SnackBar(
                        duration:
                            success
                                ? snackBarQuickSuccessDuration
                                : snackBarErrorDuration,
                        content: Text(
                          success
                              ? l10n.downloadedLanguage(
                                l10n.getLanguageName(widget.languageCode),
                              )
                              : l10n.downloadError,
                        ),
                      ),
                    );
                setState(() {
                  _isLoading = false;
                });
              },
              icon: const Icon(Icons.download),
              padding: EdgeInsets.zero,
            );

    return widget.highlight
        ? Container(
          decoration: BoxDecoration(
            color: Theme.of(context).highlightColor,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: ourWidget,
        )
        : ourWidget;
  }
}

/// Button to download all languages. While the batch runs it turns into a
/// determinate progress ring with an "n of m" caption (that's why the class
/// is stateful): 34 languages on a slow connection can take minutes, and a
/// bare spinner gives no hint whether anything is happening.
class DownloadAllLanguagesButton extends ConsumerStatefulWidget {
  const DownloadAllLanguagesButton({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _DownloadAllLanguagesButtonState();
}

class _DownloadAllLanguagesButtonState
    extends ConsumerState<DownloadAllLanguagesButton> {
  bool _isLoading = false;

  /// How many of [_total] languages of the running batch are finished
  int _completed = 0;
  int _total = 0;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              value: _total == 0 ? null : _completed / _total,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            context.l10n.downloadProgress(_completed, _total),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      );
    }
    // Same footprint as the other header buttons while idle - the table cell
    // deliberately has no fixed width so that the row above can grow
    return SizedBox(
      width: 32,
      child: IconButton(
        onPressed: () async {
          // Get l10n now as we can't access context after async gap later
          final l10n = context.l10n;
          final codesToDownload = [
            for (final languageCode in ref.read(availableLanguagesProvider))
              if (!ref.read(languageProvider(languageCode)).downloaded)
                languageCode,
          ];
          setState(() {
            _isLoading = true;
            _completed = 0;
            _total = codesToDownload.length;
          });
          final result = await downloadLanguagesInParallel(
            codesToDownload,
            download:
                (code) => ref.read(languageProvider(code).notifier).download(),
            onProgress: (progress) {
              if (!mounted) return;
              setState(() => _completed = progress.completed);
            },
          );
          if (result.successCount > 0) {
            // Show info message in snackbar
            String text =
                (result.successCount == 1)
                    ? l10n.downloadedLanguage(
                      l10n.getLanguageName(result.lastSuccessCode),
                    )
                    : l10n.downloadedNLanguages(result.successCount);
            final snackBar = SnackBar(
              content: Text(text),
              duration: snackBarQuickSuccessDuration,
            );
            ref.watch(scaffoldMessengerProvider).showSnackBar(snackBar);
          }
          if (result.errorCount > 0) {
            ref
                .watch(scaffoldMessengerProvider)
                .showSnackBar(
                  SnackBar(
                    content: Text(l10n.downloadError),
                    duration: snackBarErrorDuration,
                  ),
                );
          }
          setState(() {
            _isLoading = false;
          });
        },
        icon: const Icon(Icons.download),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
