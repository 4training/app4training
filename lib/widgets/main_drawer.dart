import 'package:flutter/material.dart';
import 'package:four_training/data/globals.dart';

import '../routes/assets_page.dart';
import '../routes/download_zip_asset_page.dart';

Widget mainDrawer(BuildContext context) {
  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: _buildLanguagesTiles(context),
    ),
  );
}

List<Widget> _buildLanguagesTiles(BuildContext ctx) {
  List<Widget> tiles = [];

  tiles.add(Padding(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
    child: Text(
      "4training",
      style: Theme.of(ctx).textTheme.displaySmall,
    ),
  ));

  List<ListTile> allPages = [];

  for (int i = 0; i < currentLanguage!.pages.length; i++) {
    String title = currentLanguage!.pages.elementAt(i).elementAt(0);
    title = title.replaceAll("_", " ");
    title = title.replaceAll(".html", "");

    allPages.add(ListTile(
      title: Text(title),
      onTap: () {
        currentIndex = i;
        Navigator.pop(ctx);
        Navigator.pushReplacementNamed(ctx, "/asset");
      },
    ));
  }

  tiles.add(ExpansionTile(
    title: Text(currentLanguage!.lang.toUpperCase()),
    leading: const Icon(Icons.menu_book),
    children: allPages,
  ));

  List<ListTile> allLanguages = [];

  for (int i = 0; i < languages.length; i++) {
    String title = languages[i].lang.toUpperCase();
    allLanguages.add(ListTile(
      title: Text(title),
      onTap: () {
        currentLanguage = languages[i];
        Navigator.pop(ctx);
        Navigator.pushReplacementNamed(ctx, "/asset");
      },
    ));
  }

  tiles.add(ExpansionTile(
    title: const Text("Languages"),
    leading: const Icon(Icons.language),
    children: allLanguages,
  ));

  var settingsIcon;
  if (newCommitsAvailable) {
    settingsIcon = Stack(
      children: const [
        Icon(Icons.settings),
        Positioned(
            top: 0,
            right: -0,
            child: Icon(Icons.brightness_1, size: 10, color: Colors.red))
      ],
    );
  } else {
    settingsIcon = const Icon(Icons.settings);
  }

  tiles.add(ListTile(
    title: const Text("Settings"),
    leading: settingsIcon,
    onTap: () {
      Navigator.pop(ctx);
      Navigator.pushNamed(ctx, '/settings');
    },
  ));
  return tiles;
}
