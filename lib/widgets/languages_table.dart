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
/// - show disk usage at the end
class LanguagesTable extends ConsumerWidget {
  /// Optional: highlight the download button of this language
  final String? highlightLang;
  const LanguagesTable({this.highlightLang, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int sizeInKB = ref.watch(diskUsageProvider);
    String countLanguages = context.l10n
        .countLanguages(ref.watch(countDownloadedLanguagesProvider));

    List<TableRow> rows = [];
    bool allDownloaded = true; // are all languages downloaded?

    // Sort languages alphabetically
    List<String> sortedLanguages =
        List.from(ref.read(availableLanguagesProvider));
    sortedLanguages.sort((a, b) => context.l10n
        .getLanguageName(a)
        .compareTo(context.l10n.getLanguageName(b)));

    // Add a table row for each language
    for (var languageCode in sortedLanguages) {
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
            child: status.updatesAvailable
                ? UpdateLanguageButton(languageCode)
                : const Text("")),
        SizedBox(
            height: 32,
            width: 32,
            child: lang.downloaded
                ? DeleteLanguageButton(languageCode)
                : DownloadLanguageButton(languageCode,
                    highlight: languageCode == highlightLang)),
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
            // header with all-languages-buttons
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
                      child: Text(
                          '${context.l10n.allLanguages} ($countAvailableLanguages)',
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
        ))),
        const SizedBox(height: 5),
        Text(
          '${context.l10n.diskUsage}: $sizeInKB kB $countLanguages',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
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
