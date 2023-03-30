import 'package:flutter/material.dart';
import 'package:four_training/data/globals.dart';

import '../routes/assets_page.dart';

Widget mainDrawer(BuildContext ctx) {
  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        const DrawerHeader(
          decoration: BoxDecoration(color: Colors.blue),
          child: Text("4training"),
        ),
        ListTile(
          title: const Text("En (0)"),
          onTap: () {
            currentLanguage = 0;
            Navigator.pop(ctx);
            Navigator.of(ctx).pushReplacement(MaterialPageRoute(
                builder: (context) => AssetsPage(
                      title: 'Assets Page ($currentLanguage)',
                    )));
          },
        ),
        ListTile(
          title: const Text("De (1)"),
          onTap: () {
            currentLanguage = 1;
            Navigator.pop(ctx);
            Navigator.of(ctx).pushReplacement(MaterialPageRoute(
                builder: (context) => AssetsPage(
                      title: 'Assets Page ($currentLanguage)',
                    )));
          },
        ),
        ListTile(
          title: const Text("Close"),
          onTap: () {
            Navigator.pop(ctx);
          },
        ),
      ],
    ),
  );
}
