import 'package:flutter/material.dart';
import 'package:four_training/data/globals.dart';
import 'package:four_training/data/resources_handler.dart';
import '../widgets/dropdownbutton_app_languages.dart';
import '../widgets/dropdownbutton_theme.dart';
import '../widgets/dropdownbutton_update_routine.dart';
import '../widgets/tablerow_download_language.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _title = "";
  String _appearance = "";
  String _appLanguage = "";
  String _theme = "";
  String _update = "";
  String _updateText = "";
  String _lastUpdate = "";
  String _updateNow = "";
  String _languages = "";
  String _languagesText = "";
  String _language = "";
  String _uptodate = "";
  String _diskUsage = "";

  @override
  initState() {
    _getText();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
            child: Column(
          children: _getContent(context),
        )),
      ),
    );
  }

  void _getText() {
    setState(() {
      for (var element in appLanguages) {
        if (element.languageCode == appLanguageCode) {
          var page = element.pages[0] as Map<String, dynamic>;
          _title = page['title'] ?? "Error";
          _appearance = page['appearance'] ?? "Error";
          _appLanguage = page['appLanguage'] ?? "Error";
          _theme = page['theme'] ?? "Error";
          _update = page['update'] ?? "Error";
          _updateText = page['update_text'] ?? "Error";
          _lastUpdate = page['last_time'] ?? "Error";
          _updateNow = page['update_now'] ?? "Error";
          _languages = page['languages'] ?? "Error";
          _languagesText = page['languages_text'] ?? "Error";
          _language = page['language'] ?? "Error";
          _uptodate = page['uptodate'] ?? "Error";
          _diskUsage = page['disk_usage'] ?? "Error";
        }
      }
    });
  }

  List<Widget> _getContent(BuildContext ctx) {
    // Fill the list with alle the widgets we need
    List<Widget> widgets = [];

    widgets.add(_getAppearance(ctx));
    widgets.add(_getUpdate(ctx));
    widgets.add(_getLanguages(ctx));

    return widgets;
  }

  Widget _getAppearance(BuildContext ctx) {
    List<Widget> widgets = [];

    widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Text(_appearance, style: Theme.of(ctx).textTheme.titleLarge)
        ])));

    widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_appLanguage, style: Theme.of(ctx).textTheme.bodyMedium),
            DropDownButtonAppLanguage(callback: _getText),
          ],
        )));

    widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_theme, style: Theme.of(ctx).textTheme.bodyMedium),
            const DropDownButtonTheme(),
          ],
        )));

    return Column(children: widgets);
  }

  Widget _getUpdate(BuildContext ctx) {
    List<Widget> widgets = [];

    widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Text(_update, style: Theme.of(ctx).textTheme.titleLarge)
        ])));

    widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_updateText, style: Theme.of(ctx).textTheme.bodyMedium),
          ],
        )));

    widgets.add(const Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            DropDownButtonUpdateRoutine(), // TODO create update routine
          ],
        )));

    widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("$_lastUpdate ", style: Theme.of(ctx).textTheme.bodyMedium),
          Text(
              languages
                  .elementAt(0)
                  .formatTimestamp(style: 'full', adjustToTimeZone: true),
              style: Theme.of(ctx).textTheme.bodyMedium)
        ])));

    widgets.add(Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
            child: Text(_updateNow),
            onPressed: () {
              clearResources().then((_) {
                Navigator.pop(ctx);
                Navigator.of(ctx).pushReplacementNamed('/');
              });
            })
      ],
    ));

    return Column(children: widgets);
  }

  Widget _getLanguages(BuildContext ctx) {
    List<Widget> widgets = [];

    widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Text(_languages, style: Theme.of(ctx).textTheme.titleLarge)
        ])));

    widgets.add(
      Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            _languagesText,
            style: Theme.of(ctx).textTheme.bodyMedium,
          )),
    );

    List<TableRow> rows = [];

    // Add the header of the table
    rows.add(TableRow(children: [
      Container(
        height: 32,
        alignment: Alignment.center,
        child: const Text(""),
      ),
      Container(
          height: 32,
          alignment: Alignment.centerLeft,
          child: Text(_language, style: Theme.of(ctx).textTheme.labelLarge)),
      Container(
          height: 32,
          alignment: Alignment.centerLeft,
          child: Text(_uptodate, style: Theme.of(ctx).textTheme.labelLarge)),
      Container(
          height: 32,
          alignment: Alignment.centerLeft,
          child: Text("", style: Theme.of(ctx).textTheme.labelLarge)),
    ]));

    // Add a table row for each language
    for (var element in languages) {
      rows.add(tableRowDownloadLanguage(element, ctx));
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

    var size = getResourcesSizeInBytes();
    var sizeKB = size / 1000;

    widgets.add(
      Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            "$_diskUsage: $sizeKB KB",
            style: Theme.of(ctx).textTheme.bodyMedium,
          )),
    );

    return Column(children: widgets);
  }
}
