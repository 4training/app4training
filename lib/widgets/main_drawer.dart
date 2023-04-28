import 'package:flutter/material.dart';
import 'package:four_training/data/globals.dart';
import 'package:four_training/widgets/upward_expansion_tile.dart';

Widget mainDrawer(BuildContext context) {
  return Drawer(
    child:  _buildDrawerElements(context),

  );
}

Column _buildDrawerElements(BuildContext ctx) {
  List<Widget> elements = [];

  // Header
  elements.add(Padding(
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
      title: Text(title, style: Theme.of(ctx).textTheme.labelMedium),
      onTap: () {
        currentIndex = i;
        Navigator.pop(ctx);
        Navigator.pushReplacementNamed(ctx, "/asset");
      },
    ));
  }

  elements.add(Expanded( child: ListView(children: allPages)));

  List<ListTile> allLanguages = [];

  for (int i = 0; i < languages.length; i++) {
    String title = languages[i].lang.toUpperCase();
    allLanguages.add(ListTile(
      title: Text(title, style: Theme.of(ctx).textTheme.labelMedium),
      onTap: () {
        currentLanguage = languages[i];
        Navigator.pop(ctx);
        Navigator.pushReplacementNamed(ctx, "/asset");
      },
    ));
  }

  elements.add(UpwardExpansionTile(
    title: Text("Languages", style: Theme.of(ctx).textTheme.labelLarge),
    leading: const Icon(Icons.language),
    expandedAlignment: Alignment.topCenter,

    children: allLanguages,
  ));



  return Column(children: elements);
}
