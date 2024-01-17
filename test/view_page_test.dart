import 'package:app4training/data/exceptions.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:app4training/routes/view_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Simplify testing of the ViewPage widget
class TestViewPage extends ConsumerWidget {
  /// To simulate different pageContentProvider behaviour
  final FutureProviderFamily<String, Resource> testPageContentProvider;
  const TestViewPage(this.testPageContentProvider, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProviderScope(
        overrides: [
          pageContentProvider.overrideWithProvider(testPageContentProvider)
        ],
        child: const MaterialApp(
            locale: Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ViewPage('Healing', 'de')));
  }
}

void main() {
  testWidgets('Test normal behaviour', (WidgetTester tester) async {
    await tester.pumpWidget(
        TestViewPage(FutureProvider.family<String, Resource>((ref, page) async {
      return 'TestContent';
    })));

    // First there should be the loading animation
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading content...'), findsOneWidget);
    await tester.pump();

    // Now our content should be shown
    expect(find.textContaining('TestContent'), findsOneWidget);
  });

  testWidgets('Test LanguageNotDownloadedException handling',
      (WidgetTester tester) async {
    await tester.pumpWidget(
        TestViewPage(FutureProvider.family<String, Resource>((ref, page) async {
      throw LanguageNotDownloadedException('de');
    })));
    await tester.pump();

    // Now we should see a warning (in German)
    expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    expect(find.text('Warnung'), findsOneWidget);
    expect(
        find.textContaining(
            'Kann Seite "Healing" nicht auf Deutsch (de) anzeigen'),
        findsOneWidget);
    expect(find.textContaining('Sprache ist nicht verfügbar'), findsOneWidget);
  });

  testWidgets('Test PageNotFoundException handling',
      (WidgetTester tester) async {
    await tester.pumpWidget(
        TestViewPage(FutureProvider.family<String, Resource>((ref, page) async {
      throw PageNotFoundException('Healing', 'de');
    })));
    await tester.pump();

    // Now we should see a warning (in German)
    expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    expect(find.text('Warnung'), findsOneWidget);
    expect(
        find.textContaining(
            'Kann Seite "Healing" nicht auf Deutsch (de) anzeigen'),
        findsOneWidget);
    expect(find.textContaining('Seite Healing/de konnte nicht gefunden werden'),
        findsOneWidget);
  });

  testWidgets('Test LanguageCorruptedException handling',
      (WidgetTester tester) async {
    await tester.pumpWidget(
        TestViewPage(FutureProvider.family<String, Resource>((ref, page) async {
      throw LanguageCorruptedException('de', 'BadLuck');
    })));
    await tester.pump();

    // Now we should see an error message in German
    expect(find.byIcon(Icons.error), findsOneWidget);
    expect(find.text('Fehler'), findsOneWidget);
    expect(
        find.textContaining(
            "Die Sprachdaten von 'Deutsch (de)' scheinen beschädigt zu sein"),
        findsOneWidget);
  });

  testWidgets('Test unexpected exception handling',
      (WidgetTester tester) async {
    await tester.pumpWidget(
        TestViewPage(FutureProvider.family<String, Resource>((ref, page) async {
      throw TestFailure;
    })));
    await tester.pump();

    // Now we should see an error (internalError in German)
    expect(find.byIcon(Icons.error), findsOneWidget);
    expect(find.text('Fehler'), findsOneWidget);
    expect(find.textContaining('Ups, das tut uns leid.'), findsOneWidget);
    expect(find.textContaining('TestFailure'), findsOneWidget);
  });
}
