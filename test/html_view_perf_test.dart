import 'package:app4training/features/perf/perf_logger.dart';
import 'package:app4training/widgets/html_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'perf_logger_test.dart';

void main() {
  tearDown(PerfLogger.reset);

  Widget htmlView(String body) => MaterialApp(
    home: Scaffold(
      body: HtmlView('<html><body>$body</body></html>', TextDirection.ltr),
    ),
  );

  testWidgets('rendering a page records its structure in page.render', (
    tester,
  ) async {
    final fileSystem = startLogger();

    await tester.pumpWidget(
      htmlView('''
<p>Intro</p>
<table>
  <tr><th>A</th><th>B</th></tr>
  <tr><td>1</td><td>2</td></tr>
  <tr><td>3</td><td><img src="x.png"></td></tr>
</table>
'''),
    );
    await tester.pumpAndSettle();
    await PerfLogger.flush();

    final renders =
        (await readRecords(
          fileSystem,
        )).where((r) => r['name'] == 'page.render').toList();
    expect(renders, hasLength(1));
    expect(renders.single['t'], 'span');
    expect(renders.single['durUs'], isA<int>());
    expect(renders.single['tables'], 1);
    expect(renders.single['rows'], 3);
    expect(renders.single['cells'], 6);
    expect(renders.single['images'], 1);
  });

  testWidgets('rebuilds of the same page record no further page.render', (
    tester,
  ) async {
    final fileSystem = startLogger();

    await tester.pumpWidget(htmlView('<p>Same</p>'));
    await tester.pumpAndSettle();
    // An unrelated rebuild above HtmlView (e.g. a snackbar or the drawer)
    await tester.pumpWidget(htmlView('<p>Same</p>'));
    await tester.pumpAndSettle();
    await PerfLogger.flush();

    final records = await readRecords(fileSystem);
    expect(records.where((r) => r['name'] == 'page.render'), hasLength(1));
  });

  testWidgets('re-renders of a page hidden under another screen are flagged', (
    tester,
  ) async {
    final fileSystem = startLogger();
    final navigatorKey = GlobalKey<NavigatorState>();
    Widget app(Brightness brightness) => MaterialApp(
      navigatorKey: navigatorKey,
      theme: ThemeData(brightness: brightness),
      home: const Scaffold(
        body: HtmlView('<p>Worksheet</p>', TextDirection.ltr),
      ),
    );

    await tester.pumpWidget(app(Brightness.light));
    await tester.pumpAndSettle();
    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const Text('Settings')),
    );
    await tester.pumpAndSettle();
    // The system switches to dark mode while the worksheet is covered
    await tester.pumpWidget(app(Brightness.dark));
    await tester.pumpAndSettle();
    await PerfLogger.flush();

    final renders = (await readRecords(
      fileSystem,
    )).where((r) => r['name'] == 'page.render');
    expect(renders.map((r) => r['hidden']), [false, true]);
  });
}
