import 'dart:async';

import 'package:app4training/l10n/l10n.dart';
import 'package:app4training/routes/view_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Share button in the top right corner of the main view.
/// Opens a dropdown with several sharing options.
/// Implemented with MenuAnchor+MenuItemButton
/// (seems to be preferred over PopupMenuButton since Material 3)
class ShareButton extends ConsumerWidget {
  const ShareButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuController = MenuController();
    final viewPage = context.findAncestorWidgetOfExactType<ViewPage>()!;
    String currentPage = viewPage.page;
    String currentLang = viewPage.langCode;

    return MenuAnchor(
        controller: menuController,
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
            icon: const Icon(Icons.share),
            tooltip: 'Share',
          );
        },
        menuChildren: [
          Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Column(
                children: [
                  Column(children: [
                    ListTile(
                      dense: true,
                      title: Text(context.l10n.openPdf),
                      leading: const ImageIcon(
                          AssetImage("assets/file-document-outline.png")),
                      onTap: () {
                        menuController.close();
                      },
                    ),
                    ListTile(
                      dense: true,
                      title: Text(context.l10n.sharePdf),
                      leading: const ImageIcon(AssetImage(
                          "assets/file-document-arrow-right-outline.png")),
                      onTap: () {
                        menuController.close();
                      },
                    ),
                    ListTile(
                        dense: true,
                        title: Text(context.l10n.openInBrowser),
                        leading: const Icon(Icons.open_in_browser),
                        onTap: () async {
                          menuController.close();
                          unawaited(launchUrl(Uri.parse(
                              'https://www.4training.net/$currentPage/$currentLang')));
                        }),
                    ListTile(
                      dense: true,
                      title: Text(context.l10n.shareLink),
                      leading: const ImageIcon(AssetImage("assets/link.png")),
                      onTap: () {
                        menuController.close();
                        Share.share(
                            'https://www.4training.net/$currentPage/$currentLang');
                      },
                    ),
                  ])
                ],
              ))
        ]);
  }
}
