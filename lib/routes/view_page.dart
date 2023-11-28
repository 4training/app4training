import 'package:app4training/data/globals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_table/flutter_html_table.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as htmldom;
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
        drawer: MainDrawer(page, langCode),
        body: pageContent.when(
            loading: () => loadingAnimation("Loading content..."),
            data: (content) => MainHtmlView(
                content,
                (Globals.rtlLanguages.contains(langCode))
                    ? TextDirection.rtl
                    : TextDirection.ltr),
            error: (e, st) => Text(
                "Couldn't find the content you are looking for: ${e.toString()}\nLanguage: $langCode")));
  }
}

/// Scrollable display of HTML content, filling most of the screen.
/// Uses the flutter_html package.
class MainHtmlView extends StatelessWidget {
  /// HTML code to display
  final String content;

  /// left-to-right or right-to-left (LTR / RTL)?
  final TextDirection direction;
  const MainHtmlView(this.content, this.direction, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
            child: Column(
          children: [
            SelectionArea(
                child: Directionality(
                    textDirection: direction,
//            child: Html(
//                data: content,
                    child: Html.fromDom(
                        document: sanitize(content),
                        extensions: const [TableHtmlExtension()],
                        style: {
                          "body": Style(fontSize: FontSize(15)),
                          "table": Style(
                              // set table width, otherwise they're broken
                              width: Width(
                                  MediaQuery.of(context).size.width - 50)),
                          "td": Style(
                              padding: const EdgeInsets.fromLTRB(5, 3, 5, 3)
                                  .htmlPadding),
                          "th": Style(
                              textAlign: TextAlign.center,
                              verticalAlign: VerticalAlign.top),
                          "h1": Style(
                              margin:
                                  Margins(top: Margin(0), bottom: Margin(0))),
                          "h2": Style(
                              margin:
                                  Margins(top: Margin(12), bottom: Margin(5))),
                          "h3": Style(
                              margin:
                                  Margins(top: Margin(10), bottom: Margin(3))),
                          "li": Style(
                              margin:
                                  Margins(top: Margin(3), bottom: Margin(3))),
                          "p": Style(
                              margin:
                                  Margins(top: Margin(3), bottom: Margin(3))),
                          "ul": Style(
                              margin:
                                  Margins(top: Margin(0), bottom: Margin(0))),
// TODO: reduce left padding/margin of <li> items
// But this doesn't seem to work in flutter_html-3.0.0-beta2
/*                      "li": Style(
                          padding: HtmlPaddings.zero, margin: Margins.zero) */
                        },
                        onAnchorTap: (url, _, __) {
                          debugPrint("Link tapped: $url");
                          if (url != null) {
                            Navigator.pushNamed(context, '/view$url');
                          }
                        })))
          ],
        )));
  }
}

/// FIXME: workarounds for bugs in flutter_html 3.0.0-beta2:
/// https://github.com/Sub6Resources/flutter_html/issues/1188
/// Get rid of <ul> and <p> in table cells to avoid completely unusable app
/// and fix some other issues
///
/// Hopefully flutter_html 3.0.0 is soon released and fixes the issues
htmldom.Document sanitize(String inputHtml) {
  var dom = parse(inputHtml);

  // Change <td><p>Content</p></td> to <td>Content</td>
  // FIXME: That could actually be fixed in the HTML generated by pywikitools
  for (var element in dom.querySelectorAll('td p')) {
    debugPrint('Warning: Found <p> element in <td>, removing...');
    element.parent!.innerHtml = element.innerHtml;
    element.remove();
  }
  // Change <th><p>Content</p></th> to <th>Content</th>
  // FIXME: That could actually be fixed in the HTML generated by pywikitools
  for (var element in dom.querySelectorAll('th p')) {
    debugPrint('Warning: Found <p> element in <th>, removing...');
    element.parent!.innerHtml = element.innerHtml;
    element.remove();
  }
  // e.g. Hearing_from_God:
  // Change <td><ul><li>item1</li><li>item2</li></ul></td> to
  // <td>• item1<br/>• item2<br/></td>
  // FIXME: Remove once the issue 1188 (see above) is solved
  for (var element in dom.querySelectorAll('td ul')) {
    debugPrint('Warning: Found <ul> element in <td>: Working around the bug');
    String newHtml = '';
    for (var li in element.children) {
      assert(li.localName == 'li');
      newHtml += '• ${li.innerHtml}<br/>';
    }
    element.parent!.innerHtml = newHtml;
    element.remove();
  }
  // e.g. "Three different voices" in Hearing_from_God or Time_with_God
  // has <th style="width:x%"> which confuses flutter_html, so remove
  // the style attribute
  for (var element in dom.querySelectorAll('th')) {
    element.attributes.remove('style');
  }

  // For all worksheets with subtitles (e.g. "Overcoming Colored Lenses"):
  // Replace <p><span style="font-size:125%"><i><b>...</b></i></span></p>
  // with <h2><i><b>...</b></i></h2>
  // FIXME: That could actually be fixed in the HTML generated by pywikitools
  for (var element in dom.querySelectorAll('p span')) {
    element.attributes.remove('style');
    var newElement = htmldom.Element.tag('h2');
    newElement.innerHtml = element.innerHtml;
    element.replaceWith(newElement);
  }

  // For God's Story (five fingers):
  // Remove <div style="margin-left:25px"
/*  for (var element in dom.querySelectorAll('div')) {
    if (element.attributes['style'] == 'margin-left:25px') {
      element.attributes['style'] = '';
    }
  }*/

  // For God's Story (five fingers):
  // put the finger images besides the explanation
  // Replace <div class="floatleft"><img .../></div><div style="margin-left:25px"><p><i>...</i></p>...
  // with <table><tr><td><img .../></td><td><i>...</i></td></tr></table><div>...
  //
  // TODO: Make this workaround obsolete somehow
  // (change the HTML source in the python backend
  //  or patch flutter-html so that it can handle the float property...)
  for (var imgElement in dom.querySelectorAll('div.floatleft img')) {
    var divNode = imgElement.parent!;
    htmldom.Element parentNode = divNode.parent!;

    // Get the sibling div node (which has style="margin-left:25px")
    for (var element in parentNode.children) {
      if (element.attributes['style'] == 'margin-left:25px') {
        debugPrint('Found the second <div>');
        // Now get the child <p> node
        for (var childElement in element.children) {
          if (childElement.localName!.toLowerCase() == 'p') {
            debugPrint('Found <p>');
            // Now construct our new Html
            var tableElement = htmldom.Element.tag('table');
            var trElement = htmldom.Element.tag('tr');
            var tdElement = htmldom.Element.tag('td');
            tdElement.innerHtml = imgElement.outerHtml;
            var tdElement2 = htmldom.Element.tag('td');
            tdElement2.innerHtml = childElement.innerHtml;
            trElement.children.add(tdElement);
            trElement.children.add(tdElement2);
            tableElement.children.add(trElement);

            divNode.replaceWith(tableElement);
            childElement.remove();
            element.attributes['style'] = '';
            break;
          }
        }
        break;
      }
    }
  }
  return dom;
}
