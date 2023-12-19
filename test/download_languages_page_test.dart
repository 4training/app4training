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

import 'download_language_button_test.dart';
import 'routes_test.dart';

/// Test DownloadLanguagesPage with default values
class TestDownloadLanguagesPage extends ConsumerWidget {
  final String languageCode;
  final TestObserver navigatorObserver;
  const TestDownloadLanguagesPage(this.languageCode, this.navigatorObserver,
      {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
        locale: Locale(languageCode),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        onGenerateRoute: (settings) => generateRoutes(settings, ref),
        navigatorObservers: [navigatorObserver],
        home: const DownloadLanguagesPage());
  }
}

/// Test DownloadLanguagesPage with defining noBackButton and continue Target
class TestDownloadLanguagesPageExt extends ConsumerWidget {
  final String languageCode;
  final TestObserver navigatorObserver;
  final bool noBackButton;
  final String continueTarget;
  const TestDownloadLanguagesPageExt(this.languageCode, this.navigatorObserver,
      {required this.noBackButton, required this.continueTarget, super.key});

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

Finder findTextButtonByText(String text) {
  return find.byWidgetPredicate(
    (Widget widget) =>
        widget is TextButton &&
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
    final container = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      languageProvider.overrideWithProvider(testLanguageProvider)
    ]);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: TestDownloadLanguagesPage('en', testObserver)));

    expect(find.text(AppLocalizationsEn().downloadLanguages), findsOneWidget);
    expect(find.text(AppLocalizationsEn().downloadLanguagesExplanation),
        findsOneWidget);
    expect(find.byType(LanguagesTable), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNWidgets(2));

    // Press the continue button
    expect(testObserver.replacedRoutes, isEmpty);
    await tester.tap(findElevatedButtonByText(AppLocalizationsEn().letsGo));
    await tester.pump();

    // Now we see the MissingAppLanguageDialog and close it
    expect(find.byType(MissingAppLanguageDialog), findsOneWidget);
    await tester.tap(findTextButtonByText(AppLocalizationsEn().gotit));
    await tester.pump();
    expect(find.byType(MissingAppLanguageDialog), findsNothing);

    // Simulate downloading English
    await container.read(languageProvider('en').notifier).download();

    // Now we press the continue button again - this time it should continue
    expect(testObserver.replacedRoutes, isEmpty);
    await tester.tap(findElevatedButtonByText(AppLocalizationsEn().letsGo));
    await tester.pump();
    expect(listEquals(testObserver.replacedRoutes, ['/home']), isTrue);
/*  TODO version 0.8
    await tester
        .tap(findElevatedButtonByText(AppLocalizationsEn().continueText));
    await tester.pump();
    expect(listEquals(testObserver.replacedRoutes, ['/onboarding/3']), isTrue);*/
  });

  testWidgets('Test ignoring of MissingAppLanguageDialog',
      (WidgetTester tester) async {
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

    // Press the continue button
    expect(testObserver.replacedRoutes, isEmpty);
    await tester.tap(findElevatedButtonByText(AppLocalizationsEn().letsGo));
    await tester.pump();

    // Now we see the MissingAppLanguageDialog and press ignore
    expect(find.byType(MissingAppLanguageDialog), findsOneWidget);
    await tester.tap(findTextButtonByText(AppLocalizationsEn().ignore));
    await tester.pump();
    expect(find.byType(MissingAppLanguageDialog), findsNothing);
    expect(listEquals(testObserver.replacedRoutes, ['/home']), isTrue);
/*  TODO version 0.8
    await tester
        .tap(findElevatedButtonByText(AppLocalizationsEn().continueText));
    await tester.pump();
    expect(listEquals(testObserver.replacedRoutes, ['/onboarding/3']), isTrue);*/
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
    final container = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      languageProvider.overrideWithProvider(testLanguageProvider)
    ]);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: TestDownloadLanguagesPageExt(
          'de',
          testObserver,
          noBackButton: true,
          continueTarget: '/test',
        )));

    // No back button
    expect(findElevatedButtonByText(AppLocalizationsDe().back), findsNothing);
// TODO version 0.8    expect(findElevatedButtonByText(AppLocalizationsDe().continueText),
    expect(
        findElevatedButtonByText(AppLocalizationsDe().letsGo), findsOneWidget);
    // Click the continue button
    expect(testObserver.replacedRoutes, isEmpty);
    await tester.tap(findElevatedButtonByText(AppLocalizationsDe().letsGo));
// TODO Version 0.8        .tap(findElevatedButtonByText(AppLocalizationsDe().continueText));
    await tester.pump();

    // Downloading English; still we see MissingAppLanguageDialog and close it
    await container.read(languageProvider('en').notifier).download();
    expect(find.byType(MissingAppLanguageDialog), findsOneWidget);
    await tester.tap(findTextButtonByText(AppLocalizationsDe().gotit));
    await tester.pump();
    expect(find.byType(MissingAppLanguageDialog), findsNothing);

    // Now we press the continue button again - this time it should continue
    await container.read(languageProvider('de').notifier).download();
    expect(testObserver.replacedRoutes, isEmpty);
    await tester.tap(findElevatedButtonByText(AppLocalizationsDe().letsGo));
    await tester.pump();

    expect(listEquals(testObserver.replacedRoutes, ['/test']), isTrue);
  });
}
