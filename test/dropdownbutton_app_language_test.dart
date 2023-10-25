import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app4training/data/globals.dart';
import 'package:app4training/widgets/dropdownbutton_app_language.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Test DropdownButtonAppLanguage with appLanguage: system default',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'appLanguage': 'system'});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: const MaterialApp(
            home: Scaffold(body: DropdownButtonAppLanguage()))));

    // Verify initial value
    expect(prefs.getString('appLanguage'), 'system');
    expect(find.text('System default'), findsOneWidget);
    expect(find.text('Deutsch (de)'), findsNothing);

    // Click on the button to expand it: Find the other options as well
    await tester.tap(find.byType(DropdownButtonAppLanguage));
    await tester.pump();
    expect(find.text('Deutsch (de)'), findsOneWidget);
    expect(find.text('English (en)'), findsOneWidget);

    // Select German and verify correct UI and saving in SharedPreferences
    await tester.tap(find.text('Deutsch (de)'));
    await tester.pump();
    expect(find.text('Deutsch (de)'), findsOneWidget);
    expect(find.text('System default'), findsNothing);
    expect(prefs.getString('appLanguage'), 'de');
  });

  testWidgets('Test DropdownButtonAppLanguage with appLanguage: German',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'appLanguage': 'de'});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: const MaterialApp(
            home: Scaffold(body: DropdownButtonAppLanguage()))));

    // Verify initial value
    expect(prefs.getString('appLanguage'), 'de');
    expect(find.text('Deutsch (de)'), findsOneWidget);
    expect(find.text('System default'), findsNothing);

    // Click on the button to expand it: Find the other options as well
    await tester.tap(find.byType(DropdownButtonAppLanguage));
    await tester.pump();
    expect(find.text('System default'), findsOneWidget);
    expect(find.text('English (en)'), findsOneWidget);

    // Select SYSTEM and verify correct UI and saving in SharedPreferences
    await tester.tap(find.text('System default'));
    await tester.pump();
    expect(find.text('System default'), findsOneWidget);
    expect(find.text('Deutsch (de)'), findsNothing);
    expect(prefs.getString('appLanguage'), 'system');
  });
}
