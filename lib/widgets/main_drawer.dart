import 'package:flutter/material.dart';
import 'package:four_training/data/globals.dart';
import 'package:four_training/data/languages.dart';
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

  for (int i = 0; i < languages.length; i++) {
    tiles.add(ListTile(
      title: Text(languages[i].lang),
      onTap: () {
        currentLanguage = languages[i];
        Navigator.pop(ctx);
        Navigator.of(ctx).pushReplacement(
            MaterialPageRoute(builder: (context) => const AssetsPage()));
      },
    ));
  }

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
