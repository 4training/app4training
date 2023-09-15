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
          await lang.deleteResources();
          await lang.init();
          ref
              .read(downloadLanguageProvider(languageCode).notifier)
              .setDownload(true);
        },
        icon: const Icon(Icons.refresh));
  }
}
