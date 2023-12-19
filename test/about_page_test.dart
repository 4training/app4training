import 'package:app4training/data/globals.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:app4training/routes/about_page.dart';
import 'package:app4training/routes/onboarding/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations_en.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  testWidgets('Basic test', (WidgetTester tester) async {
    const testVersion = '0.6.0';
    await tester.pumpWidget(ProviderScope(
        overrides: [
          packageInfoProvider.overrideWithValue(PackageInfo(
            version: testVersion,
            buildNumber: '1',
            appName: 'app4training',
            packageName: 'net.app4training',
          ))
        ],
        child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AboutPage())));

    expect(find.byType(PromoBlock), findsOneWidget);
    // are all headlines there?
    expect(find.text(AppLocalizationsEn().noCopyright), findsOneWidget);
    expect(find.text(AppLocalizationsEn().secure), findsOneWidget);
    expect(find.text(AppLocalizationsEn().worksOffline), findsOneWidget);
    expect(find.text(AppLocalizationsEn().contributing), findsOneWidget);
    expect(find.text(AppLocalizationsEn().openSource), findsOneWidget);
    expect(find.text(AppLocalizationsEn().version), findsOneWidget);
    expect(find.text(testVersion), findsOneWidget);
  });
}
