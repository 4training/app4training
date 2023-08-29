import 'package:flutter/material.dart';
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

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
            child: Column(
          children: _getContent(context),
        )),
      ),
    );
  }

  void _updateUICallback() {
    setState(() {});
  }

  List<Widget> _getContent(BuildContext ctx) {
    // Fill the list with alle the widgets we need
    List<Widget> widgets = [];

    widgets.add(_getAppearance(ctx));

    widgets.add(_getLanguages(ctx));
    widgets.add(_getUpdate(ctx));

    return widgets;
  }

  Widget _getAppearance(BuildContext ctx) {
    List<Widget> widgets = [];

    widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(context.l10n.appLanguage,
                style: Theme.of(ctx).textTheme.bodyMedium),
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

  Widget _getUpdate(BuildContext ctx) {
    List<Widget> widgets = [];

    widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Text(context.l10n.automaticUpdate,
              style: Theme.of(ctx).textTheme.titleLarge)
        ])));

    widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(context.l10n.updateText,
                style: Theme.of(ctx).textTheme.bodyMedium),
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
              style: Theme.of(ctx).textTheme.bodyMedium),
          Text(
              context.global.languages
                  .elementAt(0)
                  .formatTimestamp(style: 'full', adjustToTimeZone: true),
              style: Theme.of(ctx).textTheme.bodyMedium)
        ])));

    widgets.add(Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        UpdateNowButton(
            buttonText: context.l10n.checkNow, callback: _updateUICallback)
      ],
    ));

    return Column(children: widgets);
  }

  Widget _getLanguages(BuildContext ctx) {
    List<Widget> widgets = [];

    widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Text(context.l10n.languages,
              style: Theme.of(ctx).textTheme.titleLarge)
        ])));

    widgets.add(
      Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            context.l10n.languagesText,
            style: Theme.of(ctx).textTheme.bodyMedium,
          )),
    );

    List<TableRow> rows = [];

    // Add a table row for each language
    for (var languageCode in GlobalData.availableLanguages) {
      Language? language;

      for (Language element in context.global.languages) {
        if (element.languageCode == languageCode) language = element;
      }

      rows.add(TableRow(children: [
        Container(
            height: 32,
            alignment: Alignment.center,
            child: CheckBoxDownloadLanguage(languageCode: languageCode)),
        Container(
            height: 32,
            alignment: Alignment.centerLeft,
            child: Text(languageCode.toUpperCase(),
                style: Theme.of(ctx).textTheme.bodyMedium)),
        Container(
            height: 32,
            alignment: Alignment.centerLeft,
            child: language != null && language.commitsSinceDownload > 0
                ? UpdateLanguageButton(
                    language: language, callback: _updateUICallback)
                : const Text("")),
        Container(
            height: 32,
            alignment: Alignment.centerLeft,
            child: language == null
                ? DownloadLanguageButton(
                    languageCode: languageCode, callback: _updateUICallback)
                : DeleteLanguageButton(
                    language: language,
                    callback: _updateUICallback,
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

    widgets.add(
      Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            "${context.l10n.diskUsage}: ${context.global.getResourcesSizeInKB()} kB",
            style: Theme.of(ctx).textTheme.bodyMedium,
          )),
    );

    return Column(children: widgets);
  }
}
