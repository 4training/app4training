import 'package:app4training/data/globals.dart';
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
  static const String title = '4training';
  final String page; // Name of the currently selected page
  final String langCode;
  const ViewPage(this.page, this.langCode, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AsyncValue<String> pageContent =
        ref.watch(pageContentProvider((name: page, langCode: langCode)));
    return Scaffold(
        appBar: AppBar(
          title: const Text(title),
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
            error: (e, st) => Text(
                "Couldn't find the content you are looking for: ${e.toString()}\nLanguage: $langCode")));
  }
}
