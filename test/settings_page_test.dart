import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:four_training/data/app_language.dart';
import 'package:four_training/data/globals.dart';
import 'package:four_training/data/languages.dart';
import 'package:four_training/l10n/l10n.dart';
import 'package:four_training/routes/settings_page.dart';
import 'package:four_training/widgets/dropdownbutton_app_language.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations_de.dart';
import 'package:flutter_gen/gen_l10n/app_localizations_en.dart';

class TestSettingsPage extends ConsumerWidget {
  const TestSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLanguage appLanguage = ref.watch(appLanguageProvider);

    return MaterialApp(
        locale: appLanguage.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SettingsPage());
  }
}

class TestLanguageController extends LanguageController {
  @override
  Language build(String arg) {
    // Return dummy Language object using 42 kB
    return Language('', {}, [], {}, 42, DateTime(2023, 1, 1));
  }
}

void main() {
  testWidgets('Test changing language', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(ProviderScope(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
    ], child: const TestSettingsPage()));

    expect(find.byType(DropdownButtonAppLanguage), findsOneWidget);
    BuildContext context =
        tester.element(find.byType(DropdownButtonAppLanguage));
    final providerContainer = ProviderScope.containerOf(context);

    // Test changing language through the appLanguageProvider
    providerContainer.read(appLanguageProvider.notifier).setLocale('de');
    await tester.pump();
    expect(find.text(AppLocalizationsDe().appLanguage), findsOneWidget);
    expect(find.text(AppLocalizationsEn().appLanguage), findsNothing);
    providerContainer.read(appLanguageProvider.notifier).setLocale('en');
    await tester.pump();
    expect(find.text(AppLocalizationsDe().appLanguage), findsNothing);
    expect(find.text(AppLocalizationsEn().appLanguage), findsOneWidget);

    // Test changing language through tapping on the DropdownButton
    expect(prefs.getString('appLanguage'), 'en');
    await tester.tap(find.byType(DropdownButtonAppLanguage));
    await tester.pump();
    // There is another text label 'DE' on the settings page...
    expect(find.text('DE'), findsNWidgets(2));
    await tester.tap(find.text('DE').at(1));
    await tester.pump();
    expect(AppLocalizations.of(context).appLanguage,
        equals(AppLocalizationsDe().appLanguage));
    expect(find.text(AppLocalizationsDe().appLanguage), findsOneWidget);
    expect(find.text(AppLocalizationsEn().appLanguage), findsNothing);
    expect(prefs.getString('appLanguage'), equals('de'));
  });

  testWidgets('Test displaying memory usage on settings page',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final testLanguageProvider =
        NotifierProvider.family<LanguageController, Language, String>(() {
      return TestLanguageController();
    });

    await tester.pumpWidget(ProviderScope(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      languageProvider.overrideWithProvider(testLanguageProvider)
    ], child: const TestSettingsPage()));
    expect(find.textContaining('84 kB'), findsOneWidget);
  });
}
