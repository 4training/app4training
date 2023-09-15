import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app4training/data/updates.dart';

/// Should the language be downloaded?
/// Displays a checkbox icon if yes, otherwise just blank
/// TODO: This is now no CheckBox anymore - rename this class
class CheckBoxDownloadLanguage extends ConsumerWidget {
  final String languageCode;

  const CheckBoxDownloadLanguage({super.key, required this.languageCode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool download = ref.watch(downloadLanguageProvider(languageCode));
    return download
        ? const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.check))
        : const SizedBox(width: 32);
  }
}
