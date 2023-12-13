import 'package:app4training/data/globals.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:app4training/routes/onboarding/download_languages_page.dart';
import 'package:app4training/routes/routes.dart';
import 'package:app4training/widgets/languages_table.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations_en.dart';
import 'package:flutter_gen/gen_l10n/app_localizations_de.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'delete_language_button_test.dart';
import 'routes_test.dart';

class TestDownloadLanguagesPage extends ConsumerWidget {
  final String languageCode;
  final TestObserver navigatorObserver;
  final bool noBackButton;
  final String continueTarget;
  const TestDownloadLanguagesPage(this.languageCode, this.navigatorObserver,
      {this.noBackButton = false,
      this.continueTarget = '/onboarding/3',
      super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
        locale: Locale(languageCode),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        onGenerateRoute: (settings) => generateRoutes(settings, ref),
        navigatorObservers: [navigatorObserver],
        home: DownloadLanguagesPage(
            noBackButton: noBackButton, continueTarget: continueTarget));
  }
}

Finder findElevatedButtonByText(String text) {
  return find.byWidgetPredicate(
    (Widget widget) =>
        widget is ElevatedButton &&
        widget.child is Text &&
        (widget.child as Text).data == text,
  );
}

void main() {
  testWidgets('DownloadLanguagesPage basic test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final testLanguageProvider =
        NotifierProvider.family<LanguageController, Language, String>(() {
      return TestLanguageController(); // Simulate: all langs are downloaded
    });

    final testObserver = TestObserver();
    await tester.pumpWidget(ProviderScope(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      languageProvider.overrideWithProvider(testLanguageProvider)
    ], child: TestDownloadLanguagesPage('en', testObserver)));

    expect(find.text(AppLocalizationsEn().downloadLanguages), findsOneWidget);
    expect(find.text(AppLocalizationsEn().downloadLanguagesExplanation),
        findsOneWidget);
    expect(find.byType(LanguagesTable), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNWidgets(2));

    // Press the continue button
    expect(testObserver.replacedRoutes, isEmpty);
    await tester
        .tap(findElevatedButtonByText(AppLocalizationsEn().continueText));
    await tester.pump();
    expect(listEquals(testObserver.replacedRoutes, ['/onboarding/3']), isTrue);
  });

  testWidgets('Test DownloadLanguagesPage back button in German',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final testObserver = TestObserver();
    await tester.pumpWidget(ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: TestDownloadLanguagesPage('de', testObserver)));

    // Check that the page is translated
    expect(find.text(AppLocalizationsDe().downloadLanguages), findsOneWidget);
    expect(find.text(AppLocalizationsDe().downloadLanguagesExplanation),
        findsOneWidget);

    // Click the back button
    expect(testObserver.replacedRoutes, isEmpty);
    await tester.tap(findElevatedButtonByText(AppLocalizationsDe().back));
    await tester.pump();
    expect(listEquals(testObserver.replacedRoutes, ['/onboarding/1']), isTrue);
  });

  testWidgets('Test with no back button and other continue target',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final testLanguageProvider =
        NotifierProvider.family<LanguageController, Language, String>(() {
      return TestLanguageController(); // Simulate: all langs are downloaded
    });

    final testObserver = TestObserver();
    await tester.pumpWidget(ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          languageProvider.overrideWithProvider(testLanguageProvider)
        ],
        child: TestDownloadLanguagesPage(
          'de',
          testObserver,
          noBackButton: true,
          continueTarget: '/test',
        )));

    // No back button
    expect(findElevatedButtonByText(AppLocalizationsDe().back), findsNothing);
    expect(findElevatedButtonByText(AppLocalizationsDe().continueText),
        findsOneWidget);
    // Click the continue button
    expect(testObserver.replacedRoutes, isEmpty);
    await tester
        .tap(findElevatedButtonByText(AppLocalizationsDe().continueText));
    await tester.pump();
    expect(listEquals(testObserver.replacedRoutes, ['/test']), isTrue);
  });

  // TODO Test that initially no language is downloaded
  // TODO Test MissingAppLanguageDialog
}
