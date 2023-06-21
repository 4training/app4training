import 'package:flutter/material.dart';
import 'package:four_training/data/globals.dart';
import '../utils/assets_handler.dart';

// TODO make Setting persistent between app starts
// TODO add option to set standard language manually

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: getContent(context),
        ),
      ),
    );
  }

  List<Widget> getContent(BuildContext ctx) {
    List<Widget> widgets = [];
    widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Text("Languages", style: Theme.of(ctx).textTheme.titleLarge)
        ])));

    List<TableRow> rows = [];
    rows.add(TableRow(children: [
      TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: SizedBox(
            height: 32,
            child: Text("Language", style: Theme.of(ctx).textTheme.labelLarge)),
      ),
      TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: SizedBox(
            height: 32,
            child: Text("Downloaded on",
                style: Theme.of(ctx).textTheme.labelLarge)),
      ),
    ]));

    for (int i = 0; i < languages.length; i++) {
      String lang = languages.elementAt(i).lang;
      String day = languages.elementAt(i).timestamp.day.toString();
      String month = languages.elementAt(i).timestamp.month.toString();
      String year = languages.elementAt(i).timestamp.year.toString();
      String hour = languages.elementAt(i).timestamp.hour.toString();
      String minute = languages.elementAt(i).timestamp.minute.toString();

      rows.add(TableRow(children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: SizedBox(
              height: 32,
              child: Text(lang.toUpperCase(),
                  style: Theme.of(ctx).textTheme.labelLarge)),
        ),
        TableCell(
          child: SizedBox(
              height: 32,
              child: Text("$day.$month.$year $hour:$minute",
                  style: Theme.of(ctx).textTheme.bodyMedium)),
        )
      ]));
    }

    widgets.add(Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Table(
        children: rows,
      ),
    ));

    widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Text("Update", style: Theme.of(ctx).textTheme.titleLarge)
        ])));

    widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
            "Languages will be updated automatically, when you open the app after 7 days, after you downloaded them. You can also manually update them any time.",
            style: Theme.of(ctx).textTheme.bodyMedium)));

    if (newCommitsAvailable) {
      widgets.add(Row(
        children: [
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
              child: Icon(
                Icons.brightness_1,
                size: 10,
                color: Theme.of(ctx).colorScheme.error,
              )),
          Text("Update available!", style: Theme.of(ctx).textTheme.bodyMedium),
          const Spacer(),
          ElevatedButton(
              child: const Text("Update"),
              onPressed: () {
                clearAssets().then((_) {
                  Navigator.pop(ctx);
                  Navigator.of(ctx).pushReplacementNamed('/');
                });
              })
        ],
      ));
    } else {
      widgets.add(Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
              child: const Text("Update"),
              onPressed: () {
                clearAssets().then((_) {
                  Navigator.pop(ctx);
                  Navigator.of(ctx).pushReplacementNamed('/');
                });
              })
        ],
      ));
    }

    return widgets;
  }
}
