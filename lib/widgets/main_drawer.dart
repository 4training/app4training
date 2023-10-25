import 'dart:collection';

import 'package:app4training/data/globals.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app4training/widgets/upward_expansion_tile.dart';

import '../data/languages.dart';
import '../routes/view_page.dart';

/// Our main menu with the list of pages and the language selection at the end
class MainDrawer extends ConsumerWidget {
  final String langCode;
  const MainDrawer(this.langCode, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      Expanded(
          child: Directionality(
              textDirection: Globals.rtlLanguages.contains(langCode)
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: ListView(children: _buildPageList(context, ref)))),
      const LanguageSelection()
    ]));
  }

  /// Return ListTiles for the ListView of all pages in the selected language
  List<ListTile> _buildPageList(BuildContext context, WidgetRef ref) {
    LinkedHashMap<String, String> allTitles =
        ref.watch(languageProvider(langCode)).getPageTitles();
    List<ListTile> allPages = [];

    allTitles.forEach((englishName, translatedName) {
      allPages.add(ListTile(
        title: Text(translatedName,
            style: Theme.of(context).textTheme.labelMedium),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/view/$englishName/$langCode');
        },
      ));
    });
    return allPages;
  }
}

/// Language selection (opens upwards)
class LanguageSelection extends ConsumerWidget {
  const LanguageSelection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<ListTile> allLanguages = [];

    for (var language in Globals.availableLanguages) {
      if (!ref.watch(languageProvider(language)).downloaded) continue;
      String title = context.l10n.getLanguageName(language);
      allLanguages.add(ListTile(
        title: Text(title, style: Theme.of(context).textTheme.labelMedium),
        onTap: () {
          String currentPage =
              context.findAncestorWidgetOfExactType<ViewPage>()!.page;
          Navigator.pop(context);
          Navigator.pushNamed(context, "/view/$currentPage/$language");
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
