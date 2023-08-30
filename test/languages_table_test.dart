import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:four_training/data/globals.dart';
import 'package:four_training/data/languages.dart';
import 'package:four_training/widgets/languages_table.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_page_test.dart';

// Simulate that German is downloaded and has updates available
class TestLanguageController extends DummyLanguageController {
  @override
  Language build(String arg) {
    languageCode = (arg == 'de') ? 'de' : '';
    // For 'de', Language.downloaded will be true, for the rest it will be false
    return Language(
        languageCode, const {}, const [], const {}, '', 0, DateTime(2023));
  }

// ignore: avoid_public_notifier_properties
  @override
  bool get updatesAvailable {
    if (languageCode == 'de') return true;
    return false;
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

    SharedPreferences.setMockInitialValues(
        {'download_de': true, 'download_en': false});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      languageProvider.overrideWithProvider(testLanguageProvider)
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
