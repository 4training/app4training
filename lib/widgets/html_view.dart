import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_table/flutter_html_table.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as htmldom;

/// Scrollable display of HTML content, filling most of the screen.
/// Uses the flutter_html package.
class HtmlView extends StatelessWidget {
  /// HTML code to display
  final String content;

  /// left-to-right or right-to-left (LTR / RTL)?
  final TextDirection direction;

  const HtmlView(this.content, this.direction, {super.key});

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
                  document: sanitize(
                    content,
                    MediaQuery.of(context).platformBrightness ==
                        Brightness.dark,
                  ),
                  extensions: [
                    // Order matters: TagWrapExtension must come BEFORE
                    // TableHtmlExtension so it matches <table> first
                    // during the preparing step. It then delegates the
                    // inner build to TableHtmlExtension via
                    // prepareFromExtension(extensionsToIgnore: {this})
                    // and wraps the resulting table widget in a
                    // horizontal scroll view. Without this ordering,
                    // TableHtmlExtension wins the match and the wrap
                    // is never applied — leaving wide tables to
                    // overflow or hit "RenderBox was not laid out".
                    //
                    // Known remaining issue: on real devices the
                    // semantics pass logs a non-fatal per-frame
                    // "RenderBox was not laid out: RenderParagraph"
                    // assertion during PipelineOwner.flushSemantics,
                    // originating deep inside the
                    // LayoutGrid/LayoutBuilder cell tree built by
                    // TableHtmlExtension. Wrapping the table in
                    // SelectionContainer.disabled was tried as a
                    // workaround (mirroring raw_tooltip.dart:813-815)
                    // but did NOT fix the assertion and broke text
                    // selection across the whole page, so it was
                    // reverted. Page still renders fine; the spam is
                    // cosmetic in logs.
                    TagWrapExtension(
                      tagsToWrap: const {'table'},
                      builder: (child) => _HorizontalTableScroll(child: child),
                    ),
                    const TableHtmlExtension(),
                  ],
                  style: {
                    "body": Style(fontSize: FontSize(15)),
                    "td": Style(
                      padding:
                          const EdgeInsets.fromLTRB(5, 3, 5, 3).htmlPadding,
                    ),
                    "th": Style(
                      textAlign: TextAlign.center,
                      verticalAlign: VerticalAlign.top,
                    ),
                    "h1": Style(
                      margin: Margins(top: Margin(0), bottom: Margin(0)),
                    ),
                    "h2": Style(
                      margin: Margins(top: Margin(12), bottom: Margin(5)),
                    ),
                    "h3": Style(
                      margin: Margins(top: Margin(10), bottom: Margin(3)),
                    ),
                    "li": Style(
                      margin: Margins(top: Margin(3), bottom: Margin(3)),
                      padding: HtmlPaddings.zero,
                    ),
                    "p": Style(
                      margin: Margins(top: Margin(3), bottom: Margin(3)),
                    ),
                    "ul": Style(
                      margin: Margins(top: Margin(0), bottom: Margin(0)),
                    ),
                  },
                  onAnchorTap: (url, _, __) {
                    debugPrint("Link tapped: $url");
                    if (url != null) {
                      Navigator.pushNamed(context, '/view$url');
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wraps a rendered `<table>` in a horizontal scroll view with an
/// always-visible scrollbar. An explicit [ScrollController] is needed
/// because the scroll view sits inside a `WidgetSpan` (via
/// [TagWrapExtension]) where [PrimaryScrollController] does not apply.
/// [Scrollbar.thumbVisibility] is forced on so users can see at a glance
/// when a table extends beyond the screen and needs to be scrolled.
class _HorizontalTableScroll extends StatefulWidget {
  const _HorizontalTableScroll({required this.child});

  final Widget child;

  @override
  State<_HorizontalTableScroll> createState() => _HorizontalTableScrollState();
}

class _HorizontalTableScrollState extends State<_HorizontalTableScroll> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _controller,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        child: widget.child,
      ),
    );
  }
}

/// FIXME: workarounds for bugs in flutter_html 3.0.0-beta2:
/// https://github.com/Sub6Resources/flutter_html/issues/1188
/// Get rid of <ul> and <p> in table cells to avoid completely unusable app
/// and fix some other issues
///
/// Hopefully flutter_html 3.0.0 is soon released and fixes the issues
htmldom.Document sanitize(String inputHtml, bool isDarkMode) {
  var dom = parse(inputHtml);

  // Remove all <div class="mw-translate-fuzzy"> tags within <td>
  // and <span class="mw-translate-fuzzy"> tags within <p>
  // to fix #170 (flutter_html makes app almost unusable otherwise)
  // Actually there may be more of these tags at other places (not within <p>
  // or <td>) but as they don't cause issues I didn't bother
  // FIXME: That could actually be fixed in the HTML generated by pywikitools
  for (var element in dom.querySelectorAll('td div')) {
    if (element.attributes['class'] == 'mw-translate-fuzzy') {
      debugPrint('Found fuzzy translated content. Removing <div> tag...');
      element.parent!.innerHtml = element.innerHtml;
      element.remove();
    }
  }
  for (var element in dom.querySelectorAll('p span')) {
    if (element.attributes['class'] == 'mw-translate-fuzzy') {
      debugPrint('Found fuzzy translated content. Removing <span> tag...');
      element.parent!.innerHtml = element.innerHtml;
      element.remove();
    }
  }

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
  // e.g. Time_with_God has <table style="width:100%">. flutter_html 3.0.0
  // does NOT resolve percent widths against the containing block (see
  // CssBoxWidget._computeSize and Normalize.normalize in
  // flutter_html-3.0.0/lib/src/css_box_widget.dart): it uses the raw
  // numeric value regardless of unit, so `width: 100%` is interpreted as
  // literally 100 px and the table overflows by hundreds of pixels.
  // Strip style and width attributes from <table> so it falls back to
  // Width.auto() and our horizontal-scroll wrapper can size the table
  // to its intrinsic content width.
  for (var element in dom.querySelectorAll('table')) {
    element.attributes.remove('style');
    element.attributes.remove('width');
  }

  // For all worksheets with subtitles (e.g. "Overcoming Colored Lenses"):
  // Replace <p><span style="font-size:125%"><i><b>...</b></i></span></p>
  // with <h2><i><b>...</b></i></h2>
  // FIXME: That could actually be fixed in the HTML generated by pywikitools
  for (var element in dom.querySelectorAll('p span')) {
    assert(element.parent != null);
    var pElement = element.parent!;
    var newElement = htmldom.Element.tag('h2');
    newElement.innerHtml = element.innerHtml;
    pElement.replaceWith(newElement);
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
        // Now get the child <p> node
        for (var childElement in element.children) {
          if (childElement.localName!.toLowerCase() == 'p') {
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

  // Fix for dark mode:
  // Replace <div style="background-color: #f9f9f9; border: 1px solid black...">
  // with <div style="background-color: #090909; border: 1px solid white">
  // FIXME: That should be fixed in the HTML generated by pywikitools
  // by introducing a CSS class
  if (isDarkMode) {
    for (var element in dom.querySelectorAll('div')) {
      if (element.attributes['style'] != null) {
        String style = element.attributes['style']!;
        if (style.contains('#f9f9f9')) {
          style = style.replaceAll('#f9f9f9', '#090909');
        }
        if (style.contains('border: 1px solid black')) {
          style = style.replaceAll('solid black', 'solid white');
        }
        element.attributes['style'] = style;
      }
    }
  }

  return dom;
}
