import 'package:app4training/data/exceptions.dart';
import 'package:app4training/data/globals.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:app4training/widgets/error_message.dart';
import 'package:app4training/widgets/html_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/widgets/loading_animation.dart';
import 'package:app4training/widgets/main_drawer.dart';
import 'package:app4training/widgets/language_selection.dart';

/// The standard view of this app:
/// Show a page (worksheet)
class ViewPage extends ConsumerWidget {
  final String page; // Name of the currently selected page
  final String langCode;
  const ViewPage(this.page, this.langCode, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AsyncValue<String> pageContent =
        ref.watch(pageContentProvider((name: page, langCode: langCode)));
    return Scaffold(
        appBar: AppBar(
          title: const Text(Globals.appTitle),
          actions: const [LanguagesButton()],
        ),
        drawer: MainDrawer(page, langCode),
        body: pageContent.when(
            loading: () => loadingAnimation("Loading content..."),
            data: (content) => HtmlView(
                content,
                (Globals.rtlLanguages.contains(langCode))
                    ? TextDirection.rtl
                    : TextDirection.ltr),
            error: (e, st) {
              if (e is App4TrainingException) {
                if ((e is PageNotFoundException) ||
                    (e is LanguageNotDownloadedException)) {
                  return ErrorMessage(
                      context.l10n.warning,
                      '${context.l10n.cantDisplayPage(page, context.l10n.getLanguageName(langCode))}\n'
                      '${context.l10n.reason} ${e.toLocalizedString(context)}',
                      icon: Icons.warning_amber,
                      iconColor: Colors.black);
                } else if (e is LanguageCorruptedException) {
                  return ErrorMessage(
                      context.l10n.error, e.toLocalizedString(context));
                }
              }
              // What happened?!
              return ErrorMessage(
                  context.l10n.error, context.l10n.internalError(e.toString()));
            }));
  }
}
