import 'package:app4training/data/globals.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:app4training/routes/view_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Button in the top right corner of the main view to open language selection
/// Implemented with MenuAnchor+MenuItemButton
/// (seems to be preferred over PopupMenuButton since Material 3)
class LanguagesButton extends ConsumerWidget {
  const LanguagesButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<MenuItemButton> menuItems = [];

    // Construct items for all available translations of the current page
    for (var langCode in ref.read(availableLanguagesProvider)) {
      final language = ref.watch(languageProvider(langCode));
      if (!language.downloaded) continue;
      String currentPage =
          context.findAncestorWidgetOfExactType<ViewPage>()!.page;
      if (!language.pages.containsKey(currentPage)) continue;

      menuItems.add(MenuItemButton(
        onPressed: () {
          Navigator.pushNamed(context, "/view/$currentPage/$langCode");
        },
        child: Text(context.l10n.getLanguageName(langCode)),
      ));
    }

    return MenuAnchor(
        builder:
            (BuildContext context, MenuController controller, Widget? child) {
          return IconButton(
            onPressed: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            icon: Icon(
              Icons.translate,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            tooltip: 'Language selection',
          );
        },
        menuChildren: [
          Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Column(
                children: [
                  Text(context.l10n.languageSelectionHeader),
                  // Split list into two columns if we have many languages
                  // TODO improve decision on when to make two columns
                  // TODO better 2-column design for odd numbers of languages
                  menuItems.length > 10
                      ? Row(
                          children: [
                            Column(
                              children:
                                  menuItems.sublist(0, menuItems.length ~/ 2),
                            ),
                            Column(
                                children:
                                    menuItems.sublist(menuItems.length ~/ 2))
                          ],
                        )
                      : Column(children: menuItems),
                ],
              ))
        ]);
  }
}
