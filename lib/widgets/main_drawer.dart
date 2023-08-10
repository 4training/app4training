import 'dart:collection';

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
    LinkedHashMap<String, String> allTitles = currentLanguage!.getPageTitles();
    List<ListTile> allPages = [];

    allTitles.forEach((englishName, translatedName) {
      allPages.add(ListTile(
        title: Text(translatedName,
            style: Theme.of(context).textTheme.labelMedium),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushReplacementNamed(
              context, '/view/$englishName/${currentLanguage!.languageCode}');
        },
      ));
    });
    return allPages;
  }

  /// Language selection (opens upwards)
  UpwardExpansionTile _buildLanguageSelection(BuildContext context) {
    List<ListTile> allLanguages = [];

    for (var language in languages) {
      if(!language.downloaded) continue;
      String title = language.languageCode.toUpperCase();
      allLanguages.add(ListTile(
        title: Text(title, style: Theme.of(context).textTheme.labelMedium),
        onTap: () {
          currentLanguage = language;
          Navigator.pop(context);
          Navigator.pushReplacementNamed(
              context, "/view/$currentPage/${currentLanguage!.languageCode}");
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
