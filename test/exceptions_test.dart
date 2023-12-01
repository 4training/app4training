import 'package:app4training/data/exceptions.dart';
import 'package:file/file.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Test toString() methods of our exceptions', () {
    try {
      throw LanguageNotDownloadedException('de');
    } catch (e) {
      expect(e.toString(), "Language 'de' is not downloaded.");
    }

    try {
      throw LanguageCorruptedException(
          'de', 'Test message', const FileSystemException());
    } catch (e) {
      expect(e.toString(), contains("Language 'de' seems to be corrupted"));
      expect(e.toString(), contains('Test message'));
      expect(e.toString(), contains('FileSystemException'));
    }

    try {
      throw PageNotFoundException('Prayer', 'fr');
    } catch (e) {
      expect(e.toString(), "Couldn't find page Prayer/fr.");
    }
  });
}
