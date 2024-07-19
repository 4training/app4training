import 'dart:async';

import 'package:app4training/data/languages.dart';
import 'package:app4training/design/theme.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:app4training/routes/view_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
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
    String? pdfFile =
        ref.watch(languageProvider(currentLang)).pages[currentPage]?.pdfName;
    // Color for the PDF-related entries (greyed out if PDF is not available)
    Color pdfColor = (pdfFile != null)
        ? Theme.of(context).colorScheme.onSurface
        : Theme.of(context).disabledColor;

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
                        title: Text(context.l10n.openPdf,
                            style: TextStyle(color: pdfColor)),
                        leading: ImageIcon(
                            const AssetImage(
                                "assets/file-document-outline.png"),
                            color: pdfColor),
                        onTap: () async {
                          if (pdfFile != null) {
                            menuController.close();
                            var result = await OpenFilex.open(pdfFile);
                            debugPrint(
                                'OpenResult: ${result.message}; ${result.type}');
                          } else {
                            await showDialog(
                                context: context,
                                builder: (context) {
                                  return const PdfNotAvailableDialog();
                                });
                            menuController.close();
                          }
                        }),
                    ListTile(
                      dense: true,
                      title: Text(context.l10n.sharePdf,
                          style: TextStyle(color: pdfColor)),
                      leading: ImageIcon(
                          const AssetImage(
                              "assets/file-document-arrow-right-outline.png"),
                          color: pdfColor),
                      onTap: () async {
                        if (pdfFile != null) {
                          menuController.close();
                          await Share.shareXFiles([XFile(pdfFile)]);
                        } else {
                          await showDialog(
                              context: context,
                              builder: (context) {
                                return const PdfNotAvailableDialog();
                              });
                          menuController.close();
                        }
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

class PdfNotAvailableDialog extends StatelessWidget {
  const PdfNotAvailableDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: Text(context.l10n.sorry),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.sentiment_dissatisfied,
              size: smileySize,
              // For unknown reasons smiley is invisible otherwise
              color: Theme.of(context).colorScheme.onSurface),
          const SizedBox(height: 10),
          Text(context.l10n.pdfNotAvailable),
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
