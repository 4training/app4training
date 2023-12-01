import 'package:app4training/widgets/html_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Check some aspects of sanitize()', () {
    String testHtml = '''<html><head></head><body>
<h1>Overcoming Fear and Anger</h1>
<p><span style="font-size:125%"><i><b>Closing open doors in our lives</b></i></span>
</body></html>''';
    String expectedOutcome = '''<html><head></head><body>
<h1>Overcoming Fear and Anger</h1>
<h2><i><b>Closing open doors in our lives</b></i></h2></body></html>''';
    expect(sanitize(testHtml).outerHtml, expectedOutcome);

    testHtml = '''<html><head></head><body>
<h2>Content</h2>
<div class="floatleft"><img alt="Hand 1.png" decoding="async" height="37" src="files/Hand_1.png" width="30"></div>
<div style="margin-left:25px">
<p><i>(Thumb: Most important)</i>
</p>
</body></html>''';
    expectedOutcome = '''<html><head></head><body>
<h2>Content</h2>
<table><tr><td><img alt="Hand 1.png" decoding="async" height="37" src="files/Hand_1.png" width="30"></td><td><i>(Thumb: Most important)</i>
</td></tr></table>
<div style="">

</div></body></html>''';
    expect(sanitize(testHtml).outerHtml, expectedOutcome);
  });
}
