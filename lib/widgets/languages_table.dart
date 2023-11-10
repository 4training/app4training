import 'package:app4training/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app4training/data/globals.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/data/updates.dart';
import 'package:app4training/widgets/delete_language_button.dart';
import 'package:app4training/widgets/download_language_button.dart';
import 'package:app4training/widgets/update_language_button.dart';

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
    bool allDownloaded = true; // are all languages downloaded?

    // Add a table row for each language
    for (var languageCode in ref.read(availableLanguagesProvider)) {
      // watch this to rebuild if a Language object gets renewed
      Language lang = ref.watch(languageProvider(languageCode));
      allDownloaded = allDownloaded && lang.downloaded;
      LanguageStatus status = ref.watch(languageStatusProvider(languageCode));
      rows.add(TableRow(children: [
        SizedBox(height: 32, width: 32, child: IsDownloaded(lang.downloaded)),
        Container(
            height: 32,
            alignment: Alignment.centerLeft,
            child: Text(context.l10n.getLanguageName(languageCode),
                style: Theme.of(context).textTheme.bodyMedium)),
        SizedBox(
            height: 32,
            width: 32,
            child: lang.downloaded && status.updatesAvailable
                ? UpdateLanguageButton(languageCode)
                : const Text("")),
        SizedBox(
            height: 32,
            width: 32,
            child: lang.downloaded
                ? DeleteLanguageButton(languageCode)
                : DownloadLanguageButton(languageCode)),
      ]));
    }

    return Column(
      children: [
        Table(
          columnWidths: const {
            0: IntrinsicColumnWidth(),
            1: FlexColumnWidth(),
            2: IntrinsicColumnWidth(),
            3: IntrinsicColumnWidth(),
            4: IntrinsicColumnWidth(),
          },
          children: [
            TableRow(
                decoration: const BoxDecoration(
                    border: Border(
                        bottom: BorderSide(width: 3, color: Colors.grey))),
                children: [
                  SizedBox(
                      height: 32,
                      width: 32,
                      child: IsDownloaded(allDownloaded)),
                  Container(
                      height: 32,
                      alignment: Alignment.centerLeft,
                      child: Text(context.l10n.allLanguages,
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                  const SizedBox(
                      height: 32, width: 32, child: UpdateAllLanguagesButton()),
                  const SizedBox(
                      height: 32,
                      width: 32,
                      child: DownloadAllLanguagesButton()),
                  const SizedBox(
                      height: 32, width: 32, child: DeleteAllLanguagesButton()),
                ])
          ],
        ),
        const SizedBox(height: 5),
        Expanded(
            child: SingleChildScrollView(
                child: Table(
          //border: TableBorder.all(color: Colors.black26),
          columnWidths: const {
            0: IntrinsicColumnWidth(),
            1: FlexColumnWidth(),
            2: IntrinsicColumnWidth(),
            3: IntrinsicColumnWidth(),
          },
          children: rows,
        )))
      ],
    );
  }
}

/// Displays a ✓ (check) mark or a blank
class IsDownloaded extends StatelessWidget {
  final bool downloaded;
  const IsDownloaded(
    this.downloaded, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return downloaded
        ? const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.check))
        : const Text("");
  }
}
