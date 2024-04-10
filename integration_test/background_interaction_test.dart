import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:app4training/background/background_task.dart';
import 'package:app4training/background/background_test.dart';
import 'package:app4training/data/globals.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/main.dart';
import 'package:app4training/routes/view_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_gen/gen_l10n/app_localizations_de.dart';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test that background task gets executed', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final packageInfo = await PackageInfo.fromPlatform();

    final port = ReceivePort();
    expect(IsolateNameServer.registerPortWithName(port.sendPort, 'test'), true);
    final completer = Completer<String>();
    port.listen((data) async {
      // Waiting for the background task to finish its work
      completer.complete(data);
    });
    await Workmanager().initialize(backgroundTask, isInDebugMode: false);
    await Workmanager().registerOneOffTask("task-identifier", "testTask",
        initialDelay: const Duration(seconds: 2));

    await tester.pumpWidget(ProviderScope(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      packageInfoProvider.overrideWithValue(packageInfo)
    ], child: const App4Training()));
    expect(find.text('Loading'), findsOneWidget);

    // Wait for the background isolate to finish
    final msg = await completer.future.timeout(const Duration(seconds: 10));
    expect(msg, equals('success'));
    expect(IsolateNameServer.removePortNameMapping('test'), true);
  });

  testWidgets('Test synchronization with main isolate', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appLanguage', 'de');
    await prefs.setString('checkFrequency', 'weekly');
    final packageInfo = await PackageInfo.fromPlatform();

    final port = ReceivePort();
    expect(IsolateNameServer.registerPortWithName(port.sendPort, 'test'), true);
    final completer = Completer<String>();
    port.listen((data) async {
      // Waiting for the background task to finish its work
      completer.complete(data);
    });
    var fileSystem = await createTestFileSystem();

    await tester.pumpWidget(ProviderScope(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      packageInfoProvider.overrideWithValue(packageInfo),
      fileSystemProvider.overrideWith((ref) => fileSystem),
      // We need to mock DownloadAssetsController because we can't use a memory
      // file system to test it (it uses dart:io, not the file package)
      languageProvider.overrideWith(() => LanguageController(
          assetsController: createMockDownloadAssetsController())),
    ], child: const App4Training()));
    expect(find.text('Loading'), findsOneWidget);
    await tester.pumpAndSettle();

    // The languageStatusProvider haven't been loaded into memory yet -
    // Let's open the settings and close them again to make sure we have them
    // so that we can detect background activity later
    await tester.ensureVisible(find.text('Einstellungen'));
    await tester.tap(find.text('Einstellungen'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(Scaffold))).pop();
    await tester.pumpAndSettle();

    await Workmanager().initialize(backgroundTask, isInDebugMode: false);
    await Workmanager().registerOneOffTask("task-identifier", "testTask",
        initialDelay: const Duration(seconds: 2));

    // Wait for the background isolate to finish
    final msg = await completer.future.timeout(const Duration(seconds: 10));
    expect(msg, equals('success'));

    // Now open a worksheet to trigger the check for background activity
    await tester.tap(find.text('Grundlagen'));
    await tester.pumpAndSettle();
    expect(find.text('Schritte der Vergebung'), findsOneWidget);
    expect(find.byType(ViewPage), findsNothing);
    await tester.tap(find.text('Schritte der Vergebung'));
    await tester.pumpAndSettle();
    expect(find.byType(ViewPage), findsOneWidget);

    // Check whether the snack bar is visible
    expect(find.text(AppLocalizationsDe().foundBgActivity), findsOneWidget);
  });
}

/*
    // Alternative: Don't just simulate but really download German resources

    // Download German
    await tester.tap(find.byWidgetPredicate((widget) =>
        widget is DownloadLanguageButton && widget.languageCode == 'de'));
    await tester.pumpAndSettle();
    expect(find.text('Deutsch (de) ist nun verfügbar'), findsOneWidget);
    // Find the ScaffoldMessenger
    final scaffoldMessenger = tester.firstWidget(find.byType(ScaffoldMessenger))
        as ScaffoldMessengerState;
    // Simulate dismissing the Snackbar
    scaffoldMessenger.hideCurrentSnackBar();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Weiter'));
    await tester.pumpAndSettle();
*/
