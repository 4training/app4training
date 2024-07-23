import 'dart:async';

import 'package:app4training/data/languages.dart';
import 'package:app4training/design/theme.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:app4training/routes/view_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

// TODO: Use build_runner with flutter_gen instead
const String openPdfImage = 'assets/file-document-outline.png';
const String sharePdfImage = 'assets/file-document-arrow-right-outline.png';
const String shareLinkImage = 'assets/link.png';

/// A class around all sharing functionality to enable testing
/// (Packages: share_plus, url_launcher, open_filex)
///
/// Other options for testing (dependency injection etc.) are hard to use here
/// because of the usage of context.findAncestorWidgetOfExactType
/// so this is probably the best way to do it
class ShareService {
  /// Wraps Share.share() (package share_plus)
  Future<void> share(String text) {
    return Share.share(text);
  }

  /// Wraps Share.shareXFiles() (package share_plus)
  ///
  /// Not using the same argument List<XFile> because that would make it
  /// harder to verify that the function gets called with correct arguments
  /// with mocktail
  Future<ShareResult> shareFile(String path) {
    return Share.shareXFiles([XFile(path)]);
  }

  /// Wraps launchUrl (package url_launcher)
  Future<bool> launchUrl(Uri url) {
    return launchUrl(url);
  }

  /// Wraps OpenFilex.open (package open_filex)
  Future<OpenResult> open(String? filePath) {
    return OpenFilex.open(filePath);
  }
}

/// A provider for all sharing functionality to enable testing
final shareProvider = Provider<ShareService>((ref) {
  return ShareService();
});

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
    String url = 'https://www.4training.net/$currentPage/$currentLang';
    String? pdfFile =
        ref.watch(languageProvider(currentLang)).pages[currentPage]?.pdfPath;
    final shareService = ref.watch(shareProvider);
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
                        leading: ImageIcon(const AssetImage(openPdfImage),
                            color: pdfColor),
                        onTap: () async {
                          if (pdfFile != null) {
                            menuController.close();
                            var result = await shareService.open(pdfFile);
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
                      leading: ImageIcon(const AssetImage(sharePdfImage),
                          color: pdfColor),
                      onTap: () async {
                        if (pdfFile != null) {
                          menuController.close();
                          unawaited(shareService.shareFile(pdfFile));
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
                          unawaited(shareService.launchUrl(Uri.parse(url)));
                        }),
                    ListTile(
                      dense: true,
                      title: Text(context.l10n.shareLink),
                      leading: const ImageIcon(AssetImage(shareLinkImage)),
                      onTap: () {
                        menuController.close();
                        shareService.share(url);
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
