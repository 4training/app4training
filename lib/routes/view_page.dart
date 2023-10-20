import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_table/flutter_html_table.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/parser.dart' show parse;
import 'package:app4training/data/languages.dart';
import 'package:app4training/widgets/loading_animation.dart';
import 'package:app4training/widgets/main_drawer.dart';
import 'package:app4training/widgets/settings_button.dart';

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
        SelectionArea(
//            child: Html(
//                data: content,
            child: Html.fromDom(
                document: sanitize(content),
                extensions: const [TableHtmlExtension()],
                style: {
                  "table": Style(
                      // set table width, otherwise they're broken
                      width: Width(MediaQuery.of(context).size.width - 50))
                },
                onAnchorTap: (url, _, __) {
                  debugPrint("Link tapped: $url");
                  if (url != null) {
                    Navigator.pushNamed(context, '/view$url');
                  }
                }))
      ],
    ));
  }
}

/// FIXME: Bad workaround for bug in flutter_html 3.0.0-beta2:
/// https://github.com/Sub6Resources/flutter_html/issues/1188
/// Remove all <ul> and <p> in table cells.
/// That means some content isn't displayed! But that's still better than
/// a completely unusable app (turns completely white) when clicking
/// on some worksheets like "Training Meeting Outline" and "Hearing from God"
///
/// Hopefully flutter_html 3.0.0 is soon released and fixes the issue
sanitize(String html) {
  var dom = parse(html);
//  debugPrint("Number of p in td: ${dom.querySelectorAll('td p').length}");

  for (var element in dom.querySelectorAll('td p')) {
    debugPrint('Warning: Removing <p> element in <td> as workaround for a bug');
    element.remove();
  }
  for (var element in dom.querySelectorAll('td ul')) {
    debugPrint(
        'Warning: Removing <ul> element in <td> as workaround for a bug');
    element.remove();
  }
  return dom;
}
