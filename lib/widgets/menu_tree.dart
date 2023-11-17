import 'dart:collection';

import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:app4training/data/categories.dart';
import 'package:app4training/data/languages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Experimental: Use a menu tree where worksheets are organized by categories
/// Not sure if the animated_tree_view is really the right choice as it
/// doesn't display a colored ListTile correctly when expanding / collapsing
class MenuTree extends ConsumerWidget {
  final String page;
  final String langCode;
  const MenuTree(this.page, this.langCode, {super.key});

  /// Return TreeNode of all pages, structured into their categories
  TreeNode _buildPageTree(BuildContext context, WidgetRef ref) {
    final menuTree = TreeNode.root();
    LinkedHashMap<String, String> allTitles =
        ref.watch(languageProvider(langCode)).getPageTitles();
    final categoryNodes = <String, TreeNode>{};
    for (String category in categories) {
      TreeNode categoryNode = TreeNode(key: category, data: category);
      categoryNodes[category] = categoryNode;
      menuTree.add(categoryNode);
    }

    allTitles.forEach((englishName, translatedName) {
      if (worksheetCategories.containsKey(englishName)) {
        String category = worksheetCategories[englishName]!;
        assert(categories.contains(category));
        categoryNodes[category]!
            .add(TreeNode(key: englishName, data: translatedName));
      } else {
        debugPrint("worksheet $englishName doesn't have a category, omitting.");
      }
    });
    return menuTree;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TreeView.simple(
        tree: _buildPageTree(context, ref),
        indentation: const Indentation(width: 10),
        showRootNode: false,
        expansionIndicatorBuilder: (context, node) {
          return ChevronIndicator.rightDown(
            alignment: Alignment.centerLeft,
            tree: node,
          );
        },
        onTreeReady: (controller) {
          // Now expand the category our selected page is in
          controller
              .expandNode(controller.elementAt(worksheetCategories[page]!));
          //controller.scrollToIndex(0);
        },
        builder: (context, node) {
          debugPrint("Node: ${node.key} = ${node.data}");
          bool isCategory = categories.contains(node.key);
          bool isSelected = node.key == page;
/*          return InkWell(
            splashColor: Colors.yellow,
//            textColor: isSelected ? Colors.blue : Colors.white,
            //tileColor:
            child: Ink(
                color: isSelected ? Colors.blue : Colors.white,
                child: Padding(
                    padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                    child: Text(node.data,
                        style: Theme.of(context).textTheme.titleMedium))),
            onTap: isCategory
                ? null
                : () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/view/${node.key}/$langCode');
                  },
          );*/
          return ListTile(
            dense: true, // TODO: Use other ways to reduce height?
            // TODO: Coloring the selected item looks very buggy in the TreeView!
            tileColor: isSelected ? Colors.grey : Colors.white,
            title: Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                child: Text(node.data,
                    style: isCategory
                        ? TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .fontSize)
                        : Theme.of(context).textTheme.titleMedium)),
            onTap: isCategory
                ? null
                : () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/view/${node.key}/$langCode');
                  },
          );
        });
  }
}
