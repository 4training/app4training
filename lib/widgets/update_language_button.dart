import 'package:app4training/data/globals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app4training/data/updates.dart';
import '../data/languages.dart';

class UpdateLanguageButton extends ConsumerWidget {
  final String languageCode;
  const UpdateLanguageButton(this.languageCode, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    LanguageController lang = ref.read(languageProvider(languageCode).notifier);
    return IconButton(
        onPressed: () async {
          await lang.download(force: true);
        },
        icon: const Icon(Icons.refresh),
        padding: EdgeInsets.zero);
  }
}

/// Button to update all languages (which have an update available)
class UpdateAllLanguagesButton extends ConsumerWidget {
  const UpdateAllLanguagesButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Don't show the button if there are no updates available
    if (!ref.watch(updatesAvailableProvider)) return const Text("");

    return IconButton(
        onPressed: () async {
          for (var languageCode in ref.read(availableLanguagesProvider)) {
            final status = ref.read(languageStatusProvider(languageCode));
            if (status.updatesAvailable &&
                ref.read(languageProvider(languageCode)).downloaded) {
              ref
                  .read(languageProvider(languageCode).notifier)
                  .download(force: true);
            }
          }
        },
        icon: const Icon(Icons.refresh),
        padding: EdgeInsets.zero);
  }
}
