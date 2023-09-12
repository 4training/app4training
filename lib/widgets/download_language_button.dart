import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/languages.dart';

class DownloadLanguageButton extends ConsumerWidget {
  final String languageCode;
  const DownloadLanguageButton({super.key, required this.languageCode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    LanguageController lang =
        ref.watch(languageProvider(languageCode).notifier);

    return IconButton(
        onPressed: () async {
          // TODO: Add some feedback while we're loading (Circular progress indicator; snackbar message when finished)
          await lang.init();
        },
        icon: const Icon(Icons.download));
  }
}
