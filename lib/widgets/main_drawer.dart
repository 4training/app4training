import 'dart:collection';

import 'package:app4training/data/app_language.dart';
import 'package:app4training/data/categories.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/design/theme.dart';
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
  final String? _page; // The currently opened page
  final String? _langCode; // and its language
  const MainDrawer(this._page, this._langCode, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String appLangCode = ref.watch(appLanguageProvider).languageCode;
    Language appLanguage = ref.watch(languageProvider(appLangCode));
    Language? otherLanguage;

    List<Widget> categories = [];
    if (appLanguage.downloaded) {
      if ((_langCode != null) && (_langCode != appLangCode)) {
        otherLanguage = ref.watch(languageProvider(_langCode));
      }
      categories = Category.values.map<ExpansionTile>((Category category) {
        return _buildCategory(context, appLanguage, otherLanguage, category);
      }).toList();
    } else {
      // show error message because menu is empty
      categories = [
        Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
                context.l10n.languageNotDownloaded(
                    context.l10n.getLanguageName(appLangCode)),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                )))
      ];
    }

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
      ...maybeDirectLinksExplanation(context, otherLanguage),
      ...categories,
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

  /// If [lang] is not null, show a small explanation on these direct links
  List<Widget> maybeDirectLinksExplanation(
      BuildContext context, Language? lang) {
    if (lang == null) return [];
    return [
      Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Icon(Icons.translate),
            Text(context.l10n
                .directLinks(context.l10n.getLanguageName(lang.languageCode))),
            const SizedBox(width: 10)
          ]),
      const SizedBox(height: 5)
    ];
  }

  /// Construct ExpansionTile for one category
  /// If [otherLanguage] is not null, display direct links
  /// to translated worksheets in this language
  ExpansionTile _buildCategory(BuildContext context, Language appLanguage,
      Language? otherLanguage, Category category) {
    LinkedHashMap<String, String> allTitles = appLanguage.getPageTitles();

    // Construct the list of worksheets that belong to our category
    List<Widget> categoryContent = [];
    allTitles.forEach((englishName, translatedName) {
      if (worksheetCategories[englishName] == category) {
        // default: no link (this is a dummy)
        Widget linkToTranslation = const SizedBox();
        if (otherLanguage != null) {
          // Show link to translated worksheet
          linkToTranslation = IconButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/view/$englishName/$_langCode');
              },
              icon: const Icon(Icons.translate));
          if (!otherLanguage.pages.containsKey(englishName)) {
            // Show a greyed-out icon
            linkToTranslation = IconButton(
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return NotTranslatedDialog(otherLanguage.languageCode);
                      });
                },
                color: greyedOutColor,
                icon: const Icon(Icons.translate));
          }
        }

        categoryContent.add(Row(children: [
          const SizedBox(width: 10),
          Expanded(
              child: TextButton(
                  style: ButtonStyle(
                      alignment: Alignment.centerLeft,
                      shape: const MaterialStatePropertyAll(
                          RoundedRectangleBorder()),
                      backgroundColor: MaterialStatePropertyAll(
                          (englishName == _page)
                              ? Theme.of(context).focusColor
                              : null)),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context,
                        '/view/$englishName/${appLanguage.languageCode}');
                  },
                  child: Text(translatedName,
                      style: Theme.of(context).textTheme.titleMedium))),
          linkToTranslation
        ]));
      }
    });
    return ExpansionTile(
        title: Text(Category.getLocalized(context, category)),
        collapsedBackgroundColor: (worksheetCategories[_page] == category)
            ? Theme.of(context).highlightColor
            : null,
        controlAffinity: ListTileControlAffinity.leading,
        shape: const Border(), // remove border when tile is expanded
        initiallyExpanded: worksheetCategories[_page] == category,
        children: categoryContent);
  }
}

class NotTranslatedDialog extends StatelessWidget {
  final String languageCode;
  const NotTranslatedDialog(this.languageCode, {super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: Text(context.l10n.sorry),
        content: Text(context.l10n
            .notTranslated(context.l10n.getLanguageName(languageCode))),
        actions: <Widget>[
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(context.l10n.okay))
        ]);
  }
}
