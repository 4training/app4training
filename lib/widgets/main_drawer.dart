import 'dart:async';
import 'dart:collection';

import 'package:app4training/data/app_language.dart';
import 'package:app4training/data/categories.dart';
import 'package:app4training/data/globals.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/design/theme.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Our main menu with the list of pages, organized into categories.
/// The currently shown page is highlighted and the category it belongs to
/// is expanded.
/// In case we're currently looking at a translated worksheet
/// (different language than the app language), show icons indicating whether
/// other worksheets are available in that language or not.
///
/// Implemented with ExpansionTile - ExpansionPanelList would have been also
/// an option but ExpansionPanel has less customization options
/// (looks like you can't change the position of the expansion icon)
class MainDrawer extends StatelessWidget {
  final String? _page; // The currently opened page
  final String? _langCode; // and its language
  const MainDrawer(this._page, this._langCode, {super.key});

  @override
  Widget build(BuildContext context) {
    Widget header = ListTile(
      title: Padding(
        padding: const EdgeInsets.fromLTRB(10, 40, 10, 10),
        child: Align(
            alignment: Alignment.center,
            child: Text(context.l10n.content,
                style: Theme.of(context).textTheme.titleLarge)),
      ),
      onTap: () {
        // Drawer should be closed when user leaves the settings page
        context.findAncestorStateOfType<ScaffoldState>()?.closeDrawer();
        Navigator.pushNamed(context, '/home');
      },
    );

    return Drawer(child: TableOfContent(_page, _langCode, header: header));
  }
}

class TableOfContent extends ConsumerWidget {
  final String? _page; // The currently opened page
  final String? _langCode; // and its language
  final Widget? header;
  const TableOfContent(this._page, this._langCode, {this.header, super.key});

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
      categories = Category.values.map<CategoryTile>((Category category) {
        return CategoryTile(_page, appLanguage, category,
            otherLanguage: otherLanguage);
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

    return SingleChildScrollView(
        child: Column(children: [
      // Header
      header ?? const SizedBox(),
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
      ),
      ListTile(
        title: Text("Get in touch"),
        leading: const Icon(Icons.feedback_rounded),
        onTap: () {
          // Drawer should be closed when user leaves the settings page
          context.findAncestorStateOfType<ScaffoldState>()?.closeDrawer();
          Navigator.pushNamed(
            context,
            '/feedback',
          );
        },
      ),
      ListTile(
        title: Text(context.l10n.about),
        leading: const Icon(Icons.info),
        onTap: () {
          // Drawer should be closed when user leaves the settings page
          context.findAncestorStateOfType<ScaffoldState>()?.closeDrawer();
          Navigator.pushNamed(context, '/about');
        },
      )
    ]));
  }
}

/// ExpansionTile for one category
/// If [_otherLanguage] is not null, display icons to indicate
/// whether a worksheet is translated into this language or not
class CategoryTile extends ConsumerWidget {
  final String? _page;
  final Language _appLanguage;
  final Language? _otherLanguage;
  final Category _category;
  const CategoryTile(this._page, this._appLanguage, this._category,
      {Language? otherLanguage, super.key})
      : _otherLanguage = otherLanguage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    LinkedHashMap<String, String> allTitles = _appLanguage.getPageTitles();

    // Construct the list of worksheets that belong to our category
    List<Widget> categoryContent = [];
    allTitles.forEach((englishName, translatedName) {
      if (worksheetCategories[englishName] == _category) {
        bool isTranslated = (_otherLanguage != null) &&
            (_otherLanguage.pages.containsKey(englishName));
        // default: no icon (this is a dummy)
        Widget translationIcon = const SizedBox();
        if (_otherLanguage != null) {
          if (isTranslated) {
            // Show normal translate icon
            translationIcon = IconButton(
                onPressed: () async {
                  bool result = await showDialog(
                      context: context,
                      builder: (context) {
                        return AvailableInDialog(
                            translatedName, _otherLanguage.languageCode);
                      });
                  if (result) {
                    if (!context.mounted) return;
                    unawaited(Navigator.popAndPushNamed(context,
                        '/view/$englishName/${_otherLanguage.languageCode}'));
                  }
                },
                icon: const Icon(Icons.translate));
          } else {
            // Show a greyed-out icon
            translationIcon = IconButton(
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return NotTranslatedDialog(_otherLanguage.languageCode);
                      });
                },
                color: Theme.of(context).colorScheme.inversePrimary,
                icon: const Icon(Icons.translate));
          }
        }

        categoryContent.add(Row(children: [
          const SizedBox(width: 10),
          Expanded(
              child: TextButton(
                  style: ButtonStyle(
                      alignment: Alignment.centerLeft,
                      shape: const WidgetStatePropertyAll(
                          RoundedRectangleBorder()),
                      backgroundColor: WidgetStatePropertyAll(
                          (englishName == _page)
                              ? Theme.of(context).focusColor
                              : null)),
                  onPressed: () {
                    final destLangCode = isTranslated
                        ? _otherLanguage.languageCode
                        : _appLanguage.languageCode;
                    if ((_otherLanguage != null) && !isTranslated) {
                      ref.watch(scaffoldMessengerProvider).showSnackBar(
                          SnackBar(
                              content: Text(context.l10n.languageChangedBack(
                                  translatedName,
                                  context.l10n.getLanguageName(
                                      _otherLanguage.languageCode),
                                  context.l10n.getLanguageName(
                                      _appLanguage.languageCode)))));
                    }
                    Navigator.pop(context);
                    Navigator.pushNamed(
                        context, '/view/$englishName/$destLangCode');
                  },
                  child: Text(translatedName,
                      style: Theme.of(context).textTheme.titleMedium))),
          translationIcon
        ]));
      }
    });
    return ExpansionTile(
        title: Text(Category.getLocalized(context, _category)),
        collapsedBackgroundColor: (worksheetCategories[_page] == _category)
            ? Theme.of(context).highlightColor
            : null,
        controlAffinity: ListTileControlAffinity.leading,
        shape: const Border(), // remove border when tile is expanded
        initiallyExpanded: worksheetCategories[_page] == _category,
        children: categoryContent);
  }
}

/// Dialog when user clicks on a translate icon:
/// Worksheet is translated -> close / show page
class AvailableInDialog extends StatelessWidget {
  final String page;
  final String languageCode;
  const AvailableInDialog(this.page, this.languageCode, {super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: Text(context.l10n.translationAvailable),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(
            Icons.sentiment_satisfied,
            size: smileySize,
          ),
          const SizedBox(height: 10),
          Text(context.l10n.translationAvailableText(
              page, context.l10n.getLanguageName(languageCode)))
        ]),
        actions: <Widget>[
          TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text(context.l10n.close)),
          TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(context.l10n.showPage))
        ]);
  }
}

/// Dialog when user clicks on greyed-out translate icon:
/// Sorry, this worksheet is not yet translated -> okay
class NotTranslatedDialog extends StatelessWidget {
  final String languageCode;
  const NotTranslatedDialog(this.languageCode, {super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: Text(context.l10n.sorry),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(
            Icons.sentiment_dissatisfied,
            size: smileySize,
          ),
          const SizedBox(height: 10),
          Text(context.l10n
              .notTranslated(context.l10n.getLanguageName(languageCode))),
        ]),
        actions: <Widget>[
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(context.l10n.okay))
        ]);
  }
}
