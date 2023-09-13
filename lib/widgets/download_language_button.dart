import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:four_training/data/updates.dart';
import '../data/languages.dart';

class DownloadLanguageButton extends ConsumerWidget {
  final String languageCode;
  const DownloadLanguageButton(this.languageCode, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    LanguageController lang =
        ref.watch(languageProvider(languageCode).notifier);

    return IconButton(
        onPressed: () async {
          // TODO: Add some feedback while we're loading (Circular progress indicator; snackbar message when finished)
          await lang.init();
          ref
              .read(downloadLanguageProvider(languageCode).notifier)
              .setDownload(true);
        },
        icon: const Icon(Icons.download));
  }
}
