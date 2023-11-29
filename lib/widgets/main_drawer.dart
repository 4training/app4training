import 'package:app4training/widgets/menu_tree.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Our main menu with the list of pages and the language selection at the end
class MainDrawer extends ConsumerWidget {
  final String page; // The currently opened page
  final String langCode;
  const MainDrawer(this.page, this.langCode, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(child: MenuTree(page, langCode) //Column(children: [
/*      // Header
      Padding(
        padding: const EdgeInsets.fromLTRB(10, 40, 10, 10),
        child: Align(
            alignment: Alignment.center,
            child:
                Text("Content", style: Theme.of(context).textTheme.titleLarge)),
      ),*/
        // Menu with all the pages
//      Expanded(child: MenuTree(page, langCode)),
/*          child: Directionality(
              textDirection: Globals.rtlLanguages.contains(langCode)
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: ListView(
                  padding: EdgeInsets.zero,
                  children: _buildPageList(context, ref)))),*/
        );
  }

  /// Return ListTiles for the ListView of all pages in the selected language
/*  List<ListTile> _buildPageList(BuildContext context, WidgetRef ref) {
    LinkedHashMap<String, String> allTitles =
        ref.watch(languageProvider(langCode)).getPageTitles();
    List<ListTile> allPages = [];

    allTitles.forEach((englishName, translatedName) {
      allPages.add(ListTile(
        title: Text(translatedName,
            style: Theme.of(context).textTheme.titleMedium),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/view/$englishName/$langCode');
        },
      ));
    });
    return allPages;
  }*/
}
