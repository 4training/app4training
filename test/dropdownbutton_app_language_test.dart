import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:four_training/data/globals.dart';
import 'package:four_training/widgets/dropdownbutton_app_language.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Test DropdownButtonAppLanguage: appLanguage is system default',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'appLanguage': 'system'});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: const MaterialApp(
            home: Scaffold(body: DropdownButtonAppLanguage()))));

    // Initial value should be 'SYSTEM'
    expect(prefs.getString('appLanguage'), 'system');
    expect(find.text('SYSTEM'), findsOneWidget);
    expect(find.text('DE'), findsNothing);

    // Click on the button to expand it: Find the other options as well
    await tester.tap(find.byType(DropdownButtonAppLanguage));
    await tester.pump();
    expect(find.text('DE'), findsOneWidget);
    expect(find.text('EN'), findsOneWidget);

    // Select German and verify correct UI and saving in SharedPreferences
    await tester.tap(find.text('DE'));
    await tester.pump();
    expect(find.text('DE'), findsOneWidget);
    expect(find.text('SYSTEM'), findsNothing);
    expect(prefs.getString('appLanguage'), 'de');
  });

  testWidgets('Test DropdownButtonAppLanguage: appLanguage is German',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'appLanguage': 'de'});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: const MaterialApp(
            home: Scaffold(body: DropdownButtonAppLanguage()))));

    // Initial value should be 'SYSTEM'
    expect(prefs.getString('appLanguage'), 'de');
    expect(find.text('DE'), findsOneWidget);
    expect(find.text('SYSTEM'), findsNothing);

    // Click on the button to expand it: Find the other options as well
    await tester.tap(find.byType(DropdownButtonAppLanguage));
    await tester.pump();
    expect(find.text('SYSTEM'), findsOneWidget);
    expect(find.text('EN'), findsOneWidget);

    // Select German and verify correct UI and saving in SharedPreferences
    await tester.tap(find.text('SYSTEM'));
    await tester.pump();
    expect(find.text('SYSTEM'), findsOneWidget);
    expect(find.text('DE'), findsNothing);
    expect(prefs.getString('appLanguage'), 'system');
  });
}
