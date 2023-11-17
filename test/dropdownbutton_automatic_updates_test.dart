import 'package:app4training/widgets/dropdownbutton_automatic_updates.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app4training/data/globals.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Test DropdownButtonAutomaticUpdates with yesAlways',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'automaticUpdates': 'yesAlways'});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: const MaterialApp(
            // We need the following to access l10n; Locale is default en_US
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(body: DropdownButtonAutomaticUpdates()))));

    // Verify initial value
    expect(prefs.getString('automaticUpdates'), 'yesAlways');
    expect(find.text('yes, also via mobile data'), findsOneWidget);
    expect(find.text('require confirmation'), findsNothing);

    // Click on the button to expand it: Find the other options as well
    await tester.tap(find.byType(DropdownButtonAutomaticUpdates));
    await tester.pump();
    expect(find.text('yes, but only when in wifi'), findsOneWidget);
    expect(find.text('require confirmation'), findsOneWidget);
    expect(find.text('never'), findsOneWidget);

    // Select 'never' and verify correct UI and saving in SharedPreferences
    await tester.tap(find.text('never'));
    await tester.pump();
    expect(find.text('never'), findsOneWidget);
    expect(find.text('yes, also via mobile data'), findsNothing);
    expect(prefs.getString('automaticUpdates'), 'never');
  });

  testWidgets('Test DropdownButtonAutomaticUpdates with requireConfirmation',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(
        {'automaticUpdates': 'requireConfirmation'});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: const MaterialApp(
            // We need the following to access l10n; Locale is default en_US
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(body: DropdownButtonAutomaticUpdates()))));

    // Verify initial value
    expect(prefs.getString('automaticUpdates'), 'requireConfirmation');
    expect(find.text('require confirmation'), findsOneWidget);
    expect(find.text('never'), findsNothing);

    // Click on the button to expand it: Find the other options as well
    await tester.tap(find.byType(DropdownButtonAutomaticUpdates));
    await tester.pump();
    expect(find.text('never'), findsOneWidget);
    expect(find.text('yes, but only when in wifi'), findsOneWidget);
    expect(find.text('yes, also via mobile data'), findsOneWidget);

    // Select 'onlyOnWifi' and verify correct UI and saving in SharedPreferences
    await tester.tap(find.text('yes, but only when in wifi'));
    await tester.pump();
    expect(find.text('yes, but only when in wifi'), findsOneWidget);
    expect(find.text('require confirmation'), findsNothing);
    expect(prefs.getString('automaticUpdates'), 'onlyOnWifi');
  });
}
