import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app4training/data/globals.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/data/updates.dart';
import 'package:app4training/widgets/languages_table.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_page_test.dart';

// Simulate that German is downloaded
class TestLanguageController extends DummyLanguageController {
  @override
  Language build(String arg) {
    languageCode = (arg == 'de') ? 'de' : '';
    // For 'de', Language.downloaded will be true, for the rest it will be false
    return Language(
        languageCode, const {}, const [], const {}, '', 0, DateTime(2023));
  }
}

// Simulate that German has updates available
class TestLanguageStatusNotifier extends LanguageStatusNotifier {
  @override
  LanguageStatus build(String arg) {
    return LanguageStatus(arg == 'de', DateTime(2023));
  }
}

void main() {
  testWidgets('Basic test with no language downloaded',
      (WidgetTester tester) async {
    final testLanguageProvider =
        NotifierProvider.family<LanguageController, Language, String>(() {
      return DummyLanguageController();
    });

    SharedPreferences.setMockInitialValues(
        {'download_de': false, 'download_en': false});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      languageProvider.overrideWithProvider(testLanguageProvider)
    ], child: const MaterialApp(home: Scaffold(body: LanguagesTable()))));

    expect(find.text('DE'), findsOneWidget);
    expect(find.text('EN'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);
    expect(find.byIcon(Icons.delete), findsNothing);
    expect(find.byIcon(Icons.download), findsNWidgets(2));
    expect(find.byIcon(Icons.refresh), findsNothing);
  });
  testWidgets('Basic test with only German downloaded',
      (WidgetTester tester) async {
    final testLanguageProvider =
        NotifierProvider.family<LanguageController, Language, String>(() {
      return TestLanguageController();
    });
    final testLanguageStatusProvider =
        NotifierProvider.family<LanguageStatusNotifier, LanguageStatus, String>(
            () {
      return TestLanguageStatusNotifier();
    });

    SharedPreferences.setMockInitialValues(
        {'download_de': true, 'download_en': false});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      languageProvider.overrideWithProvider(testLanguageProvider),
      languageStatusProvider.overrideWithProvider(testLanguageStatusProvider)
    ], child: const MaterialApp(home: Scaffold(body: LanguagesTable()))));

    expect(find.text('DE'), findsOneWidget);
    expect(find.text('EN'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);

    expect(find.byIcon(Icons.delete), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
    expect(find.byIcon(Icons.download), findsOneWidget);
  });
  // TODO add more tests to check whether icons change according to user interaction
}
