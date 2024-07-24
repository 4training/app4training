import 'package:app4training/data/app_language.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/features/share/share_service.dart';
import 'package:app4training/features/share/share_button.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:app4training/routes/view_page.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import 'app_language_test.dart';
import 'languages_test.dart';

// To simplify testing the ShareButton widget in different locales
class TestShareButton extends ConsumerWidget {
  const TestShareButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
        locale: ref.watch(appLanguageProvider).locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // we need ViewPage here because ShareButton uses
        // context.findAncestorWidgetOfExactType<ViewPage>() to get current page
        home: const ViewPage('Healing', 'de'));
  }
}

/// Find an ImageIcon with an AssetImage by the name of the asset
/// (from our asset/ folder)
Finder findAssetImageIcon(String assetName, [Color? color]) {
  return find.byWidgetPredicate((Widget widget) =>
      widget is ImageIcon &&
      ((color == null) || (widget.color == color)) &&
      widget.image is AssetImage &&
      (widget.image as AssetImage).assetName == assetName);
}

class MockShareService extends Mock implements ShareService {}

void main() {
  testWidgets('Smoke test: open and close the share menu (English locale)',
      (WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [
      appLanguageProvider.overrideWith(() => TestAppLanguage('en')),
    ], child: const TestShareButton()));

    expect(find.byIcon(Icons.share), findsOneWidget);
    expect(find.text('Open PDF'), findsNothing);

    await tester.tap(find.byType(ShareButton));
    await tester.pump();

    expect(find.text('Open PDF'), findsOneWidget);
    expect(find.text('Share PDF'), findsOneWidget);
    expect(find.text('Open in browser'), findsOneWidget);
    expect(find.text('Share link'), findsOneWidget);

    expect(find.byIcon(Icons.share), findsOneWidget);
    expect(find.byIcon(Icons.open_in_browser), findsOneWidget);
    expect(findAssetImageIcon(openPdfImage), findsOneWidget);
    expect(findAssetImageIcon(sharePdfImage), findsOneWidget);
    expect(findAssetImageIcon(shareLinkImage), findsOneWidget);

    await tester.tap(find.byType(ShareButton));
    await tester.pump();
    expect(find.byIcon(Icons.share), findsOneWidget);
    expect(find.text('Open PDF'), findsNothing);
  });

  testWidgets('Test when PDFs are not available', (WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [
      appLanguageProvider.overrideWith(() => TestAppLanguage('de'))
    ], child: const TestShareButton()));

    expect(find.byIcon(Icons.share), findsOneWidget);
    expect(find.text('PDF öffnen'), findsNothing);

    await tester.tap(find.byType(ShareButton));
    await tester.pump();

    // Check also that list items are greyed out
    final BuildContext context = tester.element(find.byType(ShareButton));
    final disabledColor = Theme.of(context).disabledColor;

    // Try to open PDF - should not work because PDF is missing
    expect(find.text('PDF öffnen'), findsOneWidget);
    await tester.tap(findAssetImageIcon(openPdfImage, disabledColor));
    await tester.pumpAndSettle();
    expect(find.byType(PdfNotAvailableDialog), findsOneWidget);
    await tester.tap(find.text('Okay'));
    await tester.pumpAndSettle();
    expect(find.text('PDF öffnen'), findsNothing); // menu is closed again

    await tester.tap(find.byType(ShareButton));
    await tester.pump();

    // Try to share PDF - should not work because PDF is missing
    expect(findAssetImageIcon(sharePdfImage, disabledColor), findsOneWidget);
    final sharePdfText = find.text('PDF teilen');
    final textWidget = tester.widget<Text>(sharePdfText);
    expect(textWidget.style?.color, equals(disabledColor));
    await tester.tap(sharePdfText); // This time tap on the text
    await tester.pumpAndSettle();
    expect(find.byType(PdfNotAvailableDialog), findsOneWidget);
    await tester.tap(find.text('Okay'));
    await tester.pumpAndSettle();
    expect(find.text('PDF teilen'), findsNothing); // menu is closed again
  });

  testWidgets('Test all sharing features', (WidgetTester tester) async {
    const String testUrl = 'https://www.4training.net/Healing/de';
    const String testPath = '/path/to/Healing.pdf';

    final mockShareService = MockShareService();
    when(() => mockShareService.share(any(that: isA<String>())))
        .thenAnswer((_) async {});
    when(() => mockShareService.launchUrl(Uri.parse(testUrl)))
        .thenAnswer((_) async => true);
    when(() => mockShareService.shareFile(any())).thenAnswer((_) async {
      return const ShareResult('Success', ShareResultStatus.success);
    });
    when(() => mockShareService.open(any(that: isA<String>())))
        .thenAnswer((_) async {
      return OpenResult();
    });

    await tester.pumpWidget(ProviderScope(overrides: [
      appLanguageProvider.overrideWith(() => TestAppLanguage('de')),
      shareProvider.overrideWithValue(mockShareService),
      languageProvider.overrideWith(() => TestLanguageController(
              downloadedLanguages: [
                'de'
              ],
              pages: {
                'Healing': const Page('test', 'test', 'test', '1.0', testPath)
              }))
    ], child: const TestShareButton()));

    await tester.tap(find.byType(ShareButton));
    await tester.pump();

    // Check that list items aren't greyed out
    final BuildContext context = tester.element(find.byType(ShareButton));
    final disabledColor = Theme.of(context).disabledColor;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    expect(findAssetImageIcon(openPdfImage, onSurfaceColor), findsOneWidget);
    expect(findAssetImageIcon(sharePdfImage, onSurfaceColor), findsOneWidget);
    expect(findAssetImageIcon(sharePdfImage, disabledColor), findsNothing);

    // Open PDF
    expect(find.text('PDF öffnen'), findsOneWidget);
    await tester.tap(findAssetImageIcon(openPdfImage));
    await tester.pumpAndSettle();
    verify(() => mockShareService.open(testPath)).called(1);
    expect(find.text('PDF öffnen'), findsNothing);

    await tester.tap(find.byType(ShareButton));
    await tester.pump();

    // Share PDF
    await tester.tap(find.text('PDF teilen')); // This time tap on the text
    await tester.pumpAndSettle();
    verify(() => mockShareService.shareFile(testPath)).called(1);
    expect(find.text('PDF teilen'), findsNothing);

    await tester.tap(find.byType(ShareButton));
    await tester.pump();

    // Open in browser
    expect(find.text('Im Browser öffnen'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.open_in_browser));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.open_in_browser), findsNothing);
    verify(() => mockShareService.launchUrl(Uri.parse(testUrl))).called(1);

    await tester.tap(find.byType(ShareButton));
    await tester.pump();

    // Share link
    expect(find.text('Link teilen'), findsOneWidget);
    await tester.tap(findAssetImageIcon(shareLinkImage));
    await tester.pump();
    expect(findAssetImageIcon(shareLinkImage), findsNothing);
    verify(() => mockShareService.share(testUrl)).called(1);
  });
}
