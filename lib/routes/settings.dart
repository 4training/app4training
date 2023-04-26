import 'package:flutter/material.dart';
import 'package:four_training/data/globals.dart';

import '../utils/assets_handler.dart';

class Settings extends StatelessWidget {
  const Settings({Key? key}) : super(key: key);

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
          Text("Language", style: Theme.of(ctx).textTheme.titleLarge)
        ])));

    for (int i = 0; i < languages.length; i++) {
      String lang = languages.elementAt(i).lang;
      String day = languages.elementAt(i).timestamp.day.toString();
      String month = languages.elementAt(i).timestamp.month.toString();
      String year = languages.elementAt(i).timestamp.year.toString();
      String hour = languages.elementAt(i).timestamp.hour.toString();
      String minute = languages.elementAt(i).timestamp.minute.toString();

      Widget tile = ListTile(
        title:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(
            lang.toUpperCase(),
            style: Theme.of(ctx).textTheme.labelLarge,
          ),
          Text("Downloaded on $day.$month.$year $hour:$minute")
        ]),
      );

      widgets.add(tile);
    }

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

    return widgets;
  }
}
