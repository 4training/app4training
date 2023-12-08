import 'package:app4training/data/app_language.dart';
import 'package:app4training/data/categories.dart';
import 'package:app4training/data/globals.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:app4training/routes/onboarding/welcome_page.dart';
import 'package:app4training/routes/routes.dart';
import 'package:app4training/widgets/dropdownbutton_app_language.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations_en.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'routes_test.dart';

class TestWelcomePage extends ConsumerWidget {
  final TestObserver navigatorObserver;
  const TestWelcomePage(this.navigatorObserver, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLanguage appLanguage = ref.watch(appLanguageProvider);

    return MaterialApp(
        locale: appLanguage.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        onGenerateRoute: (settings) => generateRoutes(settings, ref),
        navigatorObservers: [navigatorObserver],
        // TODO: using home: const WelcomePage() leads to overflowing
        // RenderFlex by a few pixels because height is only 600px
        // It would be better to make the layout more flexible so that
        // it would fit on a height of 600px also including the appBar
        home: const Scaffold(body: WelcomeScreen()));
  }
}

void main() {
  testWidgets('Test PromoBlock in German', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'appLanguage': 'de'});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: TestWelcomePage(TestObserver())));

    expect(find.textContaining(countAvailableLanguages.toString()),
        findsOneWidget);
    expect(find.textContaining(worksheetCategories.length.toString()),
        findsOneWidget);
    expect(find.textContaining('offline'), findsOneWidget);
    expect(find.textContaining('Kein Copyright'), findsOneWidget);
  });

  testWidgets('WelcomePage basic test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final testObserver = TestObserver();

    await tester.pumpWidget(ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: TestWelcomePage(testObserver)));

    expect(find.text(AppLocalizationsEn().welcome), findsOneWidget);
    expect(find.text(AppLocalizationsEn().selectAppLanguage), findsOneWidget);
    expect(find.byType(DropdownButtonAppLanguage), findsOneWidget);
    expect(find.byType(PromoBlock), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);

    expect(testObserver.replacedRoutes, isEmpty);
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    expect(listEquals(testObserver.replacedRoutes, ['/onboarding/2']), isTrue);
  });

  testWidgets('appLanguage should get saved in SharedPrefs when user continues',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: TestWelcomePage(TestObserver())));

    expect(prefs.getString('appLanguage'), null);
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    // Even if user doesn't touch the appLanguage, after clicking "Continue"
    // there should be an entry in the SharedPreferences
    expect(prefs.getString('appLanguage'), 'system');
  });

  testWidgets('Test that changing the app language to German works',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'appLanguage': 'system'});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: TestWelcomePage(TestObserver())));

    // Select German and verify correct UI and saving in SharedPreferences
    expect(prefs.getString('appLanguage'), 'system');
    await tester.tap(find.byType(DropdownButtonAppLanguage));
    await tester.pump();
    await tester.tap(find.text('Deutsch (de)'));
    await tester.pump();
    expect(find.text('Herzlich Willkommen!'), findsOneWidget);
    expect(prefs.getString('appLanguage'), 'de');
  });
}
