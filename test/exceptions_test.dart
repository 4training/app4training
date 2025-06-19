import 'package:app4training/data/exceptions.dart';
import 'package:app4training/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:file/file.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Test toString() methods of our exceptions', () {
    try {
      throw LanguageNotDownloadedException('de');
    } catch (e) {
      expect(e.toString(), startsWith("Language isn't available"));
    }

    try {
      throw LanguageCorruptedException(
          'de', 'Test message', const FileSystemException());
    } catch (e) {
      expect(e.toString(),
          startsWith("Language data for 'de' seems to be corrupted"));
      expect(e.toString(), contains('Test message'));
      expect(e.toString(), contains('FileSystemException'));
    }

    try {
      throw PageNotFoundException('Prayer', 'fr');
    } catch (e) {
      expect(e.toString(), startsWith('Page Prayer/fr not found.'));
    }
  });

  testWidgets('Test translated error messages', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Container(),
    ));
    BuildContext context = tester.element(find.byType(Container));
    try {
      throw LanguageNotDownloadedException('de');
    } on App4TrainingException catch (e) {
      expect(e.toLocalizedString(context),
          startsWith("Sprache ist nicht verfügbar"));
    }

    try {
      throw LanguageCorruptedException(
          'de', 'Test message', const FileSystemException());
    } on App4TrainingException catch (e) {
      expect(
          e.toLocalizedString(context),
          startsWith(
              "Die Sprachdaten von 'Deutsch (de)' scheinen beschädigt zu sein"));
      expect(e.toLocalizedString(context), contains('Test message'));
      expect(e.toLocalizedString(context), contains('FileSystemException'));
    }

    try {
      throw PageNotFoundException('Prayer', 'fr');
    } on App4TrainingException catch (e) {
      expect(e.toLocalizedString(context),
          startsWith('Seite Prayer/fr konnte nicht gefunden werden.'));
    }
  });
}
