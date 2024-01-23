import 'package:app4training/data/app_language.dart';
import 'package:app4training/data/globals.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:app4training/widgets/delete_language_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_language_test.dart';
import 'languages_test.dart';

class TestDeleteLanguageButton extends ConsumerWidget {
  final String languageCode;
  const TestDeleteLanguageButton(this.languageCode, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
        locale: ref.watch(appLanguageProvider).locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        scaffoldMessengerKey: ref.read(scaffoldMessengerKeyProvider),
        home: Scaffold(body: DeleteLanguageButton(languageCode)));
  }
}

void main() {
  testWidgets('Test DeleteLanguageButton', (WidgetTester tester) async {
    final testLanguageController = TestLanguageController();
    final ref = ProviderContainer(overrides: [
      appLanguageProvider.overrideWith(() => TestAppLanguage('de')),
      languageProvider.overrideWith(() => testLanguageController)
    ]);

    await tester.pumpWidget(UncontrolledProviderScope(
        container: ref, child: const TestDeleteLanguageButton('en')));

    expect(find.byIcon(Icons.delete), findsOneWidget);
    expect(testLanguageController.state.downloaded, true);
    expect(ref.read(languageProvider('en')).downloaded, true);

    await tester.tap(find.byType(DeleteLanguageButton));
    await tester.pump();
    expect(testLanguageController.state.downloaded, false);
    expect(ref.read(languageProvider('en')).downloaded, false);
    // Snackbar visible?
    expect(find.text('Englisch (en) wurde gelöscht'), findsOneWidget);
    /* TODO: Check that snackbar is disappearing - somehow doesn't work
    await tester.pump(snackBarErrorDuration);
    expect(find.text('Englisch (en) wurde gelöscht'), findsNothing);*/
  });

  // Trying to delete the currently selected app language is discouraged
  testWidgets('Test DeleteLanguageButton for app language',
      (WidgetTester tester) async {
    final ref = ProviderContainer(overrides: [
      appLanguageProvider.overrideWith(() => TestAppLanguage('de')),
      languageProvider.overrideWith(() => TestLanguageController())
    ]);

    await tester.pumpWidget(UncontrolledProviderScope(
        container: ref, child: const TestDeleteLanguageButton('de')));

    expect(find.byIcon(Icons.delete), findsOneWidget);
    // TODO test that the color of the icon is greyed out
    expect(ref.read(languageProvider('de')).downloaded, true);

    await tester.tap(find.byType(DeleteLanguageButton));
    await tester.pump();
    // The ConfirmDeletionDialog should be visible now: we cancel
    expect(find.byType(ConfirmDeletionDialog), findsOneWidget);
    expect(find.text('Abbrechen'), findsOneWidget);
    expect(find.text('Löschen'), findsOneWidget);
    await tester.tap(find.text('Abbrechen'));
    await tester.pump();
    expect(find.byType(ConfirmDeletionDialog), findsNothing);
    expect(ref.read(languageProvider('de')).downloaded, true);

    // This time we really delete
    await tester.tap(find.byType(DeleteLanguageButton));
    await tester.pump();
    expect(find.text('Löschen'), findsOneWidget);
    await tester.tap(find.text('Löschen'));
    await tester.pump();
    expect(find.byType(ConfirmDeletionDialog), findsNothing);
    expect(ref.read(languageProvider('de')).downloaded, false);
  });

  testWidgets('Test DeleteAllLanguagesButton', (WidgetTester tester) async {
    final ref = ProviderContainer(overrides: [
      appLanguageProvider.overrideWith(() => TestAppLanguage('de')),
      languageProvider.overrideWith(() => TestLanguageController())
    ]);

    await tester.pumpWidget(UncontrolledProviderScope(
        container: ref,
        child: MaterialApp(
            locale: ref.read(appLanguageProvider).locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            scaffoldMessengerKey: ref.read(scaffoldMessengerKeyProvider),
            home: const Scaffold(body: DeleteAllLanguagesButton()))));

    expect(ref.read(languageProvider('ar')).downloaded, true);

    expect(find.byIcon(Icons.delete), findsOneWidget);
    await tester.tap(find.byType(DeleteAllLanguagesButton));
    await tester.pump();

    expect(ref.read(languageProvider('ar')).downloaded, false);
    expect(ref.read(languageProvider('en')).downloaded, false);
    expect(ref.read(languageProvider('de')).downloaded, true);
    // Snackbar visible?
    expect(find.text('33 Sprachen gelöscht'), findsOneWidget);
  });
}
