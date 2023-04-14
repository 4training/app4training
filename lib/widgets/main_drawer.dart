import 'package:flutter/material.dart';
import 'package:four_training/data/globals.dart';
import 'package:four_training/data/languages.dart';
import 'package:four_training/design/textthemes.dart';
import 'package:four_training/utils/assets_handler.dart';

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

  tiles.add(const DrawerHeader(
    decoration: BoxDecoration(),
    child: Text("4training"),
  ));

  List<ListTile> allPages = [];

  for(int i = 0; i < currentLanguage!.pages.length; i++) {
    String title = currentLanguage!.pages.elementAt(i).toString();
    title = title.replaceAll("_", " ");
    title = title.replaceAll(".html", "");

    allPages.add(ListTile(
    title: Text(title),
      onTap: () {
        currentIndex = i;
        Navigator.pop(ctx);
        Navigator.of(ctx).pushReplacement(
            MaterialPageRoute(builder: (context) => const AssetsPage()));
      },
    ));

  }

  tiles.add(ExpansionTile(
    title: Text(currentLanguage!.lang.toUpperCase()),
    children: allPages,
  ));

  List<ListTile> allLanguages = [];

  for (int i = 0; i < languages.length; i++) {
    String title = languages[i].lang.toUpperCase();

    allLanguages.add(ListTile(
      title:  Text(title),
      onTap: () {
        currentLanguage = languages[i];
        Navigator.pop(ctx);
        Navigator.of(ctx).pushReplacement(
            MaterialPageRoute(builder: (context) => const AssetsPage()));
      },
    ));
  }

  tiles.add(ExpansionTile(
    title: const Text("Switch Language"),
    children: allLanguages,
  ));

  tiles.add(ListTile(
    title: const Text("Clear assets"),
    onTap: () async {
      await clearAssets();
      if (ctx.mounted) {
        Navigator.pop(ctx);
        Navigator.of(ctx).pushReplacement(MaterialPageRoute(
            builder: (context) =>
                const DownloadZipAssetPage(title: 'DownloadZipAsset')));
      }
    },
  ));

  tiles.add(ListTile(
    title: const Text("Close"),
    onTap: () {
      Navigator.pop(ctx);
    },
  ));

  return tiles;
}
