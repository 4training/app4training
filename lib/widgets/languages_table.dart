import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:four_training/data/globals.dart';
import 'package:four_training/data/languages.dart';
import 'package:four_training/widgets/checkbox_download_language.dart';
import 'package:four_training/widgets/delete_language_button.dart';
import 'package:four_training/widgets/download_language_button.dart';
import 'package:four_training/widgets/update_language_button.dart';

/// For the settings page: Show table with list of available languages.
/// Features:
/// - select which of them should be available offline
/// - delete language files
/// - download language files (if not yet downloaded)
/// - update language if updates are available
class LanguagesTable extends ConsumerWidget {
  const LanguagesTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<TableRow> rows = [];

    // Add a table row for each language
    for (var languageCode in Globals.availableLanguages) {
      // watch this to rebuild if a Language object gets renewed
      ref.watch(languageProvider(languageCode));
      LanguageController lang =
          ref.watch(languageProvider(languageCode).notifier);
      rows.add(TableRow(children: [
        Container(
            height: 32,
            alignment: Alignment.center,
            child: CheckBoxDownloadLanguage(languageCode: languageCode)),
        Container(
            height: 32,
            alignment: Alignment.centerLeft,
            child: Text(languageCode.toUpperCase(),
                style: Theme.of(context).textTheme.bodyMedium)),
        Container(
            height: 32,
            alignment: Alignment.centerLeft,
            child: lang.downloaded && lang.updatesAvailable
                ? UpdateLanguageButton(languageCode)
                : const Text("")),
        Container(
            height: 32,
            alignment: Alignment.centerLeft,
            child: lang.downloaded
                ? DeleteLanguageButton(languageCode)
                : DownloadLanguageButton(languageCode)),
      ]));
    }

    return Table(
      //border: TableBorder.all(color: Colors.black26),
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: FlexColumnWidth(),
        2: IntrinsicColumnWidth(),
        3: IntrinsicColumnWidth(),
      },
      children: rows,
    );
  }
}
