import 'package:flutter/material.dart';
import 'package:four_training/data/globals.dart';
import 'package:four_training/widgets/upward_expansion_tile.dart';

/// Our main menu with the list of pages and the language selection at the end
class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: Column(children: [
      // Header
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 10),
        child: Align(
            alignment: Alignment.topLeft,
            child:
                Text("Content", style: Theme.of(context).textTheme.titleLarge)),
      ),
      // Menu with all the pages
      Expanded(child: ListView(children: _buildPageList(context))),
      // Language selection at the end
      _buildLanguageSelection(context),
    ]));
  }

  /// Return ListTiles for the ListView of all pages in the selected language
  List<ListTile> _buildPageList(BuildContext context) {
    List<String> allTitles = currentLanguage!.getPageTitles();
    List<ListTile> allPages = [];

    for (int i = 0; i < allTitles.length; i++) {
      String title = allTitles.elementAt(i);
      title = title.replaceAll("_", " ");
      title = title.replaceAll(".html", "");

      allPages.add(ListTile(
        title: Text(title, style: Theme.of(context).textTheme.labelMedium),
        // selected: i == currentIndex, // TODO not working
        onTap: () {
          currentIndex = i;
          Navigator.pop(context);
          Navigator.pushReplacementNamed(context, "/view/");
        },
      ));
    }
    return allPages;
  }

  /// Language selection (opens upwards)
  UpwardExpansionTile _buildLanguageSelection(BuildContext context) {
    List<ListTile> allLanguages = [];

    for (int i = 0; i < languages.length; i++) {
      String title = languages[i].languageCode.toUpperCase();
      allLanguages.add(ListTile(
        title: Text(title, style: Theme.of(context).textTheme.labelMedium),
        onTap: () {
          currentLanguage = languages[i];
          Navigator.pop(context);
          Navigator.pushReplacementNamed(context, "/view/");
        },
      ));
    }

    return UpwardExpansionTile(
      title: Text("Languages", style: Theme.of(context).textTheme.labelLarge),
      leading: const Icon(Icons.language),
      expandedAlignment: Alignment.topCenter,
      children: allLanguages,
    );
  }
}
