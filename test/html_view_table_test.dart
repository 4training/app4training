import 'dart:io';

import 'package:app4training/widgets/html_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reproduces the "RenderBox was not laid out" crashes reported on pages
/// like Essentials > Time With God that contain tables. Only goal here:
/// make sure HtmlView can render common table shapes without throwing.
void main() {
  Future<void> pump(WidgetTester tester, String body) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HtmlView(
          '<html><body>$body</body></html>',
          TextDirection.ltr,
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('renders a simple 2x2 table', (tester) async {
    await pump(tester, '''
<table>
  <tr><th>A</th><th>B</th></tr>
  <tr><td>1</td><td>2</td></tr>
</table>
''');
    expect(tester.takeException(), isNull);
  });

  testWidgets('wraps each <table> in a visible horizontal Scrollbar',
      (tester) async {
    // Guards the UX affordance: users need a visible scroll thumb to
    // discover that wide tables are horizontally scrollable.
    await pump(tester, '''
<table>
  <tr><th>H1</th><th>H2</th></tr>
  <tr><td>1</td><td>2</td></tr>
</table>
<table>
  <tr><th>Other</th></tr>
  <tr><td>x</td></tr>
</table>
''');
    expect(tester.takeException(), isNull);
    // Expect one Scrollbar per table. The outer page scroll is a
    // SingleChildScrollView without a Scrollbar, so every Scrollbar found
    // here belongs to a _HorizontalTableScroll wrapper.
    expect(find.byType(Scrollbar), findsNWidgets(2));
    // And the scroll direction inside each wrapper must be horizontal.
    final horizontalScrolls = tester
        .widgetList<SingleChildScrollView>(find.byType(SingleChildScrollView))
        .where((w) => w.scrollDirection == Axis.horizontal)
        .toList();
    expect(horizontalScrolls.length, 2);
  });

  testWidgets('renders a table with long non-breaking cell content', (tester) async {
    // Long single token that cannot wrap — this is the kind of content that
    // causes layout problems on some translations of Time With God.
    await pump(tester, '''
<table>
  <tr><th>Heading</th><th>Another heading</th></tr>
  <tr>
    <td>Supercalifragilisticexpialidocious_long_word_that_cannot_wrap_naturally</td>
    <td>Short</td>
  </tr>
</table>
''');
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders a wide many-column table', (tester) async {
    await pump(tester, '''
<table>
  <tr>
    <th>Col1</th><th>Col2</th><th>Col3</th><th>Col4</th>
    <th>Col5</th><th>Col6</th><th>Col7</th><th>Col8</th>
  </tr>
  <tr>
    <td>row 1 cell 1 with some text</td>
    <td>row 1 cell 2 with some text</td>
    <td>row 1 cell 3 with some text</td>
    <td>row 1 cell 4 with some text</td>
    <td>row 1 cell 5 with some text</td>
    <td>row 1 cell 6 with some text</td>
    <td>row 1 cell 7 with some text</td>
    <td>row 1 cell 8 with some text</td>
  </tr>
</table>
''');
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders a table with th[style] (stripped by sanitize)',
      (tester) async {
    await pump(tester, '''
<table>
  <tr>
    <th style="width:33%">One</th>
    <th style="width:33%">Two</th>
    <th style="width:34%">Three</th>
  </tr>
  <tr>
    <td>Short cell</td>
    <td>Medium length cell content that wraps</td>
    <td>Some other content here that is longer than the others</td>
  </tr>
</table>
''');
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders a table with empty <td> cells (fill-in-the-blank)',
      (tester) async {
    // Real Time_with_God table shape: lots of empty cells for users to fill in.
    await pump(tester, '''
<table class="wikitable" style="width:100%">
  <tbody>
    <tr>
      <th scope="col">Verse</th>
      <th scope="col" style="width:20%">Person</th>
      <th scope="col" style="width:20%">Time</th>
      <th scope="col" style="width:20%">Place</th>
      <th scope="col" style="width:25%">What exactly?</th>
    </tr>
    <tr>
      <td>Psalms 5:3</td>
      <td style="text-align:center">David</td>
      <td style="text-align:center">in the morning</td>
      <td style="text-align:center">?</td>
      <td style="text-align:center">praying and waiting for answer</td>
    </tr>
    <tr><td>Daniel 6:11</td><td></td><td></td><td></td><td></td></tr>
    <tr><td>Mark 1:35</td><td></td><td></td><td></td><td></td></tr>
    <tr><td>Luke 6:12</td><td></td><td></td><td></td><td></td></tr>
    <tr><td>Acts 10:9</td><td></td><td></td><td></td><td></td></tr>
    <tr><td>Acts 16:25</td><td></td><td></td><td></td><td></td></tr>
  </tbody>
</table>
''');
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders a <table> nested inside a <li> (Time_with_God shape)',
      (tester) async {
    // This is the exact shape from Time_with_God line 70: a table inside a
    // list item inside a ul. It uses a <br/> before the nested table.
    await pump(tester, '''
<ul>
  <li><b>Bible:</b> Read a passage and think about it. Use the head-heart-hands questions:<br/>
    <table>
      <tbody>
        <tr>
          <td><img alt="Head-32.png" height="32" width="32"/></td>
          <td><b>Head:</b> What do I learn here?</td>
        </tr>
        <tr>
          <td><img alt="Heart-32.png" height="32" width="32"/></td>
          <td><b>Heart:</b> What touches my heart?</td>
        </tr>
        <tr>
          <td><img alt="Hands-32.png" height="32" width="32"/></td>
          <td><b>Hands:</b> How can I apply this?</td>
        </tr>
      </tbody>
    </table>
  </li>
  <li><b>Place:</b> Choose a quiet place.</li>
  <li><b>Time:</b> Find the best time.</li>
</ul>
''');
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders the real Time_with_God fixture end-to-end',
      (tester) async {
    // Pumping the exact page content that was crashing in production.
    // Critically:
    // 1. enable semantics — on a real device the semantics pass walks the
    //    render tree and trips `RenderBox.size` assertions on any unlaid
    //    RenderParagraph; without this handle flutter_test skips
    //    flushSemantics and hides the bug;
    // 2. use a phone-sized surface — the default 800x600 flutter_test
    //    surface is wide enough that the Time_with_God table fits without
    //    horizontal overflow, so the horizontal-scroll / LayoutGrid path
    //    that triggers the assertion on real devices never runs.
    final semantics = tester.ensureSemantics();
    try {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final html = File('test/assets-en/html-en-main/Time_with_God.html')
          .readAsStringSync();
      await pump(tester, html);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.binding.setSurfaceSize(null);
      semantics.dispose();
    }
  });

  testWidgets('renders a table wrapped in the standard page chrome',
      (tester) async {
    // Mimics the structure of a real Time With God page: headings,
    // paragraphs, and a table together.
    await pump(tester, '''
<h1>Time with God</h1>
<p>Introduction paragraph describing the topic.</p>
<h2>Three different voices</h2>
<table>
  <tr><th>Voice</th><th>Source</th><th>Effect</th></tr>
  <tr><td>Yourself</td><td>Your own thoughts</td><td>Self-centered</td></tr>
  <tr><td>Enemy</td><td>The enemy</td><td>Accusing, fearful</td></tr>
  <tr><td>God</td><td>Holy Spirit</td><td>Loving, convicting</td></tr>
</table>
<p>Follow-up text after the table.</p>
''');
    expect(tester.takeException(), isNull);
  });
}
