import 'package:app4training/l10n/l10n.dart';
import 'package:app4training/routes/about_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations_en.dart';

void main() {
  testWidgets('Basic test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AboutPage()));

    // are all headlines there?
    expect(find.text(AppLocalizationsEn().appDescription), findsOneWidget);
    expect(find.text(AppLocalizationsEn().trustworthy), findsOneWidget);
    expect(find.text(AppLocalizationsEn().worksOffline), findsOneWidget);
    expect(find.text(AppLocalizationsEn().contributing), findsOneWidget);
    expect(find.text(AppLocalizationsEn().openSource), findsOneWidget);
    expect(find.text(AppLocalizationsEn().version), findsOneWidget);
  });
}
