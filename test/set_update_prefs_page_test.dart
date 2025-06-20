import 'package:app4training/background/background_scheduler.dart';
import 'package:app4training/data/app_language.dart';
import 'package:app4training/data/globals.dart';
import 'package:app4training/l10n/generated/app_localizations.dart';
import 'package:app4training/l10n/generated/app_localizations_de.dart';
import 'package:app4training/l10n/generated/app_localizations_en.dart';
import 'package:app4training/routes/onboarding/set_update_prefs_page.dart';
import 'package:app4training/routes/routes.dart';
import 'package:app4training/widgets/dropdownbutton_automatic_updates.dart';
import 'package:app4training/widgets/dropdownbutton_check_frequency.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_language_test.dart';
import 'background_scheduler_test.dart';
import 'routes_test.dart';

class TestSetUpdatePrefsPage extends ConsumerWidget {
  final TestObserver navigatorObserver;
  const TestSetUpdatePrefsPage(this.navigatorObserver, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
        locale: ref.watch(appLanguageProvider).locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        onGenerateRoute: (settings) => generateRoutes(settings),
        navigatorObservers: [navigatorObserver],
        home: const SetUpdatePrefsPage());
  }
}

void main() {
  testWidgets('SetUpdatePrefsPage basic test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final testObserver = TestObserver();
    final ref = ProviderContainer(overrides: [
      appLanguageProvider.overrideWith(() => TestAppLanguage('en')),
      backgroundSchedulerProvider.overrideWith(() => TestBackgroundScheduler()),
      sharedPrefsProvider.overrideWithValue(prefs)
    ]);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: ref, child: TestSetUpdatePrefsPage(testObserver)));

    expect(ref.read(backgroundSchedulerProvider), false);
    expect(find.text(AppLocalizationsEn().updatesExplanation), findsOneWidget);
    expect(find.text(AppLocalizationsEn().doAutomaticUpdates), findsOneWidget);
    expect(find.byType(DropdownButtonAutomaticUpdates), findsOneWidget);
    expect(find.byType(DropdownButtonCheckFrequency), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNWidgets(2));

    // Press the "Let's go!" button
    expect(testObserver.replacedRoutes, isEmpty);
    await tester
        .tap(find.widgetWithText(ElevatedButton, AppLocalizationsEn().letsGo));
    await tester.pump();
    expect(listEquals(testObserver.replacedRoutes, ['/home']), isTrue);
    // Even if user didn't change any setting, after clicking "Continue"
    // there should be an entry in the SharedPreferences
    expect(prefs.getString('checkFrequency'), 'weekly');
    expect(prefs.getString('automaticUpdates'), 'onlyOnWifi');
    expect(ref.read(backgroundSchedulerProvider), true);
  });

  testWidgets('Test SetUpdatePrefsPage back button in German',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final testObserver = TestObserver();
    await tester.pumpWidget(ProviderScope(overrides: [
      appLanguageProvider.overrideWith(() => TestAppLanguage('de')),
      sharedPrefsProvider.overrideWithValue(prefs)
    ], child: TestSetUpdatePrefsPage(testObserver)));

    // Check that the page is in German
    expect(find.text(AppLocalizationsDe().updatesExplanation), findsOneWidget);
    expect(find.text(AppLocalizationsDe().doAutomaticUpdates), findsOneWidget);

    // Click the back button
    expect(testObserver.replacedRoutes, isEmpty);
    await tester
        .tap(find.widgetWithText(ElevatedButton, AppLocalizationsDe().back));
    await tester.pump();
    expect(listEquals(testObserver.replacedRoutes, ['/onboarding/2']), isTrue);
  });
}
