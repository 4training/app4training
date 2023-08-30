import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:four_training/data/globals.dart';
import 'package:four_training/l10n/l10n.dart';
import 'package:four_training/widgets/update_now_button.dart';
import '../data/languages.dart';
import '../widgets/checkbox_download_language.dart';
import '../widgets/delete_language_button.dart';
import '../widgets/download_language_button.dart';
import '../widgets/dropdownbutton_app_language.dart';
import '../widgets/dropdownbutton_check_frequency.dart';
import '../widgets/update_language_button.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
            child: Column(children: [
          _getAppearance(context),
          const LanguageSettings(),
          const UpdateSettings()
        ])),
      ),
    );
  }

  Widget _getAppearance(BuildContext context) {
    List<Widget> widgets = [];

    widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(context.l10n.appLanguage,
                style: Theme.of(context).textTheme.bodyMedium),
            const DropdownButtonAppLanguage(),
          ],
        )));

    /* This will be part of a later version of the app
    widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(context.l10n.theme, style: Theme.of(ctx).textTheme.bodyMedium),
            const DropDownButtonTheme(),
          ],
        )));
     */

    return Column(children: widgets);
  }
}

class LanguageSettings extends ConsumerWidget {
  const LanguageSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<Widget> widgets = [];

    widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Text(context.l10n.languages,
              style: Theme.of(context).textTheme.titleLarge)
        ])));

    widgets.add(
      Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            context.l10n.languagesText,
            style: Theme.of(context).textTheme.bodyMedium,
          )),
    );

    List<TableRow> rows = [];

    // Add a table row for each language
    for (var languageCode in Globals.availableLanguages) {
      Language language = ref.watch(languageProvider(languageCode));

      // TODO read the language specifics

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
            child:
                language.languageCode != '' && language.commitsSinceDownload > 0
                    ? UpdateLanguageButton(language: language, callback: () {})
                    : const Text("")),
        Container(
            height: 32,
            alignment: Alignment.centerLeft,
            child: language.languageCode == ''
                ? DownloadLanguageButton(
                    languageCode: languageCode, callback: () {})
                : DeleteLanguageButton(
                    languageCode: languageCode,
//                    callback: _updateUICallback,
                  )),
      ]));
    }

    // Add the table to the widget tree
    widgets.add(Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Table(
        //border: TableBorder.all(color: Colors.black26),
        columnWidths: const {
          0: IntrinsicColumnWidth(),
          1: FlexColumnWidth(),
          2: IntrinsicColumnWidth(),
          3: IntrinsicColumnWidth(),
        },
        children: rows,
      ),
    ));

    // TODO move this calculation somewhere else?
    int sizeInKB = 0;
    for (String langCode in Globals.availableLanguages) {
      sizeInKB += ref.watch(languageProvider(langCode)).sizeInKB;
    }

    widgets.add(
      Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            "${context.l10n.diskUsage}: $sizeInKB kB",
            style: Theme.of(context).textTheme.bodyMedium,
          )),
    );

    return Column(children: widgets);
  }
}

class UpdateSettings extends ConsumerWidget {
  const UpdateSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: We always display the timestamp of English
    Language currentLanguage = ref.watch(languageProvider('en'));
    List<Widget> widgets = [];

    widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Text(context.l10n.automaticUpdate,
              style: Theme.of(context).textTheme.titleLarge)
        ])));

    widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(context.l10n.updateText,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        )));

    widgets.add(const Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            DropdownButtonCheckFrequency(),
          ],
        )));

    widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("${context.l10n.lastTime} ",
              style: Theme.of(context).textTheme.bodyMedium),
          Text(
              currentLanguage.formatTimestamp(
                  style: 'full', adjustToTimeZone: true),
              style: Theme.of(context).textTheme.bodyMedium)
        ])));

    widgets.add(Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        UpdateNowButton(buttonText: context.l10n.checkNow, callback: () {})
      ],
    ));

    return Column(children: widgets);
  }
}
