import 'package:app4training/data/globals.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app4training/data/updates.dart';
import '../data/languages.dart';

/// Button to download a language. Shows a CircularProgressIndicator while
/// the download is in progress (that's why the class is stateful)
class DownloadLanguageButton extends ConsumerStatefulWidget {
  final String languageCode;
  const DownloadLanguageButton(this.languageCode, {super.key});

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

    return _isLoading
        ? const Center(
            child: SizedBox(
                height: 24, width: 24, child: CircularProgressIndicator()))
        : IconButton(
            onPressed: () async {
              setState(() {
                _isLoading = true;
              });
              final snackBar = SnackBar(
                  content: Text(context.l10n.downloadedLanguage(
                      context.l10n.getLanguageName(widget.languageCode))));
              await lang.init();
              ref
                  .read(downloadLanguageProvider(widget.languageCode).notifier)
                  .setDownload(true);
              ref.watch(scaffoldMessengerProvider).showSnackBar(snackBar);
              setState(() {
                _isLoading = false;
              });
            },
            icon: const Icon(Icons.download));
  }
}
