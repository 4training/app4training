import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:four_training/data/languages.dart';
import 'package:four_training/widgets/loading_animation.dart';
import 'package:four_training/widgets/main_drawer.dart';
import 'package:four_training/widgets/settings_button.dart';

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
          actions: const [SettingsButton()],
        ),
        drawer: MainDrawer(langCode),
        body: pageContent.when(
            loading: () => loadingAnimation("Loading content..."),
            data: (content) => MainHtmlView(content),
            error: (e, st) => Text(
                "Couldn't find the content you are looking for: ${e.toString()}\nLanguage: $langCode")));
  }
}

/// Scrollable display of HTML content, filling most of the screen.
/// Uses the flutter_html package.
class MainHtmlView extends StatelessWidget {
  /// HTML code to display
  final String content;
  const MainHtmlView(this.content, {super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Column(
      children: [
        Html(
            data: content,
            onAnchorTap: (url, _, __) {
              debugPrint("Link tapped: $url");
              if (url != null) {
                Navigator.pushNamed(context, '/view$url');
              }
            })
      ],
    ));
  }
}
