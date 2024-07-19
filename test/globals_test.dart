import 'package:app4training/data/globals.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Test remote URLs and local path', () {
    expect(
        Globals.getRemoteUrlHtml('de'),
        equals(
            'https://github.com/4training/html-de/archive/refs/heads/main.zip'));
    expect(
        Globals.getRemoteUrlPdf('de'),
        equals(
            'https://github.com/4training/pdf-de/archive/refs/heads/main.zip'));
    expect(Globals.getAssetsDir('de'), equals('assets-de'));
    expect(Globals.getResourcesDir('de'), equals('html-de-main'));
    expect(
        Globals.getCommitsSince('de', DateTime.utc(2023)),
        equals(
            'https://api.github.com/repos/4training/html-de/commits?since=2023-01-01T00:00:00.000Z'));
  });
}
