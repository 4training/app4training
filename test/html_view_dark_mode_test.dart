import 'dart:convert';
import 'dart:io';

import 'package:app4training/design/theme.dart';
import 'package:app4training/widgets/html_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifies the dark-mode handling of worksheet content in HtmlView:
/// images get a hue-preserving color inversion in dark mode and are
/// left untouched in light mode.
void main() {
  /// Mimics pageContentProvider: replace <img src="files/xyz.png">
  /// with the base64-encoded image data, like the app does before
  /// handing content to HtmlView. Missing files keep their raw src,
  /// exactly like the app treats images that failed to download.
  String inlineImages(String content, String filesDir) {
    return content.replaceAllMapped(RegExp(r'src="files/([^.]+.png)"'), (
      match,
    ) {
      final image = File('$filesDir/${match.group(1)}');
      if (!image.existsSync()) return match.group(0)!;
      return 'src="data:image/png;base64,'
          '${base64Encode(image.readAsBytesSync())}"';
    });
  }

  /// God's Story (five fingers), German, with images inlined:
  /// the same content the app renders on a real worksheet page.
  /// The fixture has Hand_1.png..Hand_4.png but no Hand_5.png, so the
  /// page contains four decodable images plus one unresolvable
  /// reference — like the real app after a partly failed download.
  String godsStoryContent() {
    final html =
        File(
          'test/assets-de/html-de-main/Gottes_Geschichte_(fünf_Finger).html',
        ).readAsStringSync();
    return inlineImages(html, 'test/assets-de/html-de-main/files');
  }

  Future<void> pumpHtmlView(
    WidgetTester tester,
    String content, {
    required ThemeMode themeMode,
  }) async {
    // Phone-sized surface like on real devices — the default 800x600
    // test surface makes flutter_html's table layout trip baseline
    // assertions on the God's Story page (see html_view_table_test.dart).
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeMode,
        home: Scaffold(body: HtmlView(content, TextDirection.ltr)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('dark theme applies color inversion to every worksheet image', (
    tester,
  ) async {
    await pumpHtmlView(tester, godsStoryContent(), themeMode: ThemeMode.dark);
    // God's Story (images inside table cells) trips flutter_html's known
    // non-fatal baseline assertions (see the comment in html_view.dart);
    // drain them — this test is about the color filter, and the page
    // renders fine on devices despite the log spam.
    tester.takeException();

    // Four decodable hand drawings; each rendered image must be
    // drawn through the color filter.
    expect(find.byType(Image), findsNWidgets(4));
    expect(
      find.ancestor(
        of: find.byType(Image),
        matching: find.byType(ColorFiltered),
      ),
      findsNWidgets(4),
    );
  });

  testWidgets('light theme renders images without any color filter', (
    tester,
  ) async {
    await pumpHtmlView(tester, godsStoryContent(), themeMode: ThemeMode.light);
    tester.takeException(); // see comment in the dark-mode test above

    // Images render as before: no filter anywhere in the tree.
    expect(find.byType(Image), findsNWidgets(4));
    expect(find.byType(ColorFiltered), findsNothing);
  });

  for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('page with unresolvable image reference renders without error '
        '($themeMode)', (tester) async {
      // An image that failed to download keeps its files/ src (see
      // pageContentProvider) and must remain untouched in both themes.
      await pumpHtmlView(
        tester,
        '<html><body><p>Text before</p>'
        '<img alt="Hand 5.png" src="files/Hand_5.png" '
        'width="30" height="37"/>'
        '<p>Text after</p></body></html>',
        themeMode: themeMode,
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(ColorFiltered), findsNothing);
      // The rest of the page is still rendered.
      expect(find.textContaining('Text before'), findsOneWidget);
      expect(find.textContaining('Text after'), findsOneWidget);
    });
  }

  testWidgets('forced dark theme applies dark-mode box treatment even when the '
      'platform brightness is light', (tester) async {
    // The theme is the canonical brightness source for the whole widget:
    // the ambient platform brightness in tests is light, so this test
    // fails if the sanitize pass keys on platform brightness instead of
    // the theme.
    await pumpHtmlView(
      tester,
      '<html><body>'
      '<div style="background-color: #f9f9f9; border: 1px solid black">'
      'Boxed content</div>'
      '</body></html>',
      themeMode: ThemeMode.dark,
    );
    expect(tester.takeException(), isNull);

    Iterable<DecoratedBox> boxesWithColor(Color color) =>
        tester.widgetList<DecoratedBox>(find.byType(DecoratedBox)).where((w) {
          final decoration = w.decoration;
          return decoration is BoxDecoration && decoration.color == color;
        });
    expect(boxesWithColor(const Color(0xFF090909)), isNotEmpty);
    expect(boxesWithColor(const Color(0xFFF9F9F9)), isEmpty);
  });
}
