import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app4training/data/app_language.dart';
import 'package:app4training/data/globals.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:app4training/routes/settings_page.dart';
import 'package:app4training/widgets/dropdownbutton_app_language.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations_de.dart';
import 'package:flutter_gen/gen_l10n/app_localizations_en.dart';

import 'app_language_test.dart';
import 'languages_test.dart';

class TestSettingsPage extends ConsumerWidget {
  const TestSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
        locale: ref.watch(appLanguageProvider).locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SettingsPage());
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
    await tester.tap(find.text('Deutsch (de)'));
    await tester.pump();
    expect(AppLocalizations.of(context).appLanguage,
        equals(AppLocalizationsDe().appLanguage));
    expect(find.text(AppLocalizationsDe().appLanguage), findsOneWidget);
    expect(find.text(AppLocalizationsEn().appLanguage), findsNothing);
    expect(prefs.getString('appLanguage'), equals('de'));
  });

  testWidgets('Test displaying memory usage on settings page',
      (WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [
      appLanguageProvider.overrideWith(() => TestAppLanguage('en')),
      languageProvider.overrideWith(() => DummyLanguageController())
    ], child: const TestSettingsPage()));
    int expectedSize = 42 * countAvailableLanguages;
    expect(find.textContaining('$expectedSize kB'), findsOneWidget);
    // language counter visibility basic test
    expect(find.textContaining('(0 languages)'), findsOneWidget);
  });
}
