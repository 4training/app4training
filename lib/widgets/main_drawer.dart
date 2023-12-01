import 'dart:collection';

import 'package:app4training/data/app_language.dart';
import 'package:app4training/data/categories.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Our main menu with the list of pages, organized into categories.
/// The currently shown page is highlighted and the category it belongs to
/// is expanded.
/// Also add links to translations in case we're currently looking at a
/// translated worksheet (different language than the app language).
///
/// Implemented with ExpansionTile - ExpansionPanelList would have been also
/// an option but ExpansionPanel has less customization options
/// (looks like you can't change the position of the expansion icon)
class MainDrawer extends ConsumerWidget {
  final String page; // The currently opened page
  final String langCode;
  const MainDrawer(this.page, this.langCode, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
        child: SingleChildScrollView(
            child: Column(children: [
      // Header
      Padding(
        padding: const EdgeInsets.fromLTRB(10, 40, 10, 10),
        child: Align(
            alignment: Alignment.center,
            child: Text(context.l10n.content,
                style: Theme.of(context).textTheme.titleLarge)),
      ),
      ...Category.values.map<ExpansionTile>((Category category) {
        return _buildCategory(context, ref, category);
      }),
      const Divider(),
      ListTile(
        title: Text(context.l10n.settings),
        leading: const Icon(Icons.settings),
        onTap: () {
          // Drawer should be closed when user leaves the settings page
          context.findAncestorStateOfType<ScaffoldState>()?.closeDrawer();
          Navigator.pushNamed(context, '/settings');
        },
      )
    ])));
  }

  /// Construct ExpansionTile for one category
  ExpansionTile _buildCategory(
      BuildContext context, WidgetRef ref, Category category) {
    String appLanguage = ref.watch(appLanguageProvider).languageCode;
    LinkedHashMap<String, String> allTitles =
        ref.watch(languageProvider(appLanguage)).getPageTitles();

    // Construct the list of worksheets that belong to our category
    List<Widget> categoryContent = [];
    allTitles.forEach((englishName, translatedName) {
      if (worksheetCategories[englishName] == category) {
        // If we're currently looking at a translation:
        // Show direct links to (existing) translated worksheets
        bool showTranslationLink = (langCode != appLanguage) &&
            ref
                .watch(languageProvider(langCode))
                .pages
                .containsKey(englishName);

        categoryContent.add(Row(children: [
          const SizedBox(width: 10),
          Expanded(
              child: TextButton(
                  style: ButtonStyle(
                      alignment: Alignment.centerLeft,
                      shape: const MaterialStatePropertyAll(
                          RoundedRectangleBorder()),
                      backgroundColor: MaterialStatePropertyAll(
                          (englishName == page)
                              ? Theme.of(context).focusColor
                              : null)),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                        context, '/view/$englishName/$appLanguage');
                  },
                  child: Text(translatedName,
                      style: Theme.of(context).textTheme.titleMedium))),
          showTranslationLink
              ? TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                        context, '/view/$englishName/$langCode');
                  },
                  child: Text('[$langCode]'))
              : const SizedBox()
        ]));
      }
    });
    return ExpansionTile(
        title: Text(Category.getLocalized(context, category)),
        collapsedBackgroundColor: (worksheetCategories[page] == category)
            ? Theme.of(context).highlightColor
            : null,
        controlAffinity: ListTileControlAffinity.leading,
        shape: const Border(), // remove border when tile is expanded
        initiallyExpanded: worksheetCategories[page] == category,
        children: categoryContent);
  }
}
