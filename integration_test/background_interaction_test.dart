import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:app4training/background_task.dart';
import 'package:app4training/data/globals.dart';
import 'package:app4training/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

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
    await Workmanager().initialize(
        backgroundTask, // The top level function, aka callbackDispatcher
        isInDebugMode:
            false // If enabled it will post a notification whenever the task is running. Handy for debugging tasks
        );
    await Workmanager().registerOneOffTask("task-identifier", "simpleTask",
        initialDelay: const Duration(seconds: 2));

    await tester.pumpWidget(ProviderScope(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      packageInfoProvider.overrideWithValue(packageInfo)
    ], child: const App4Training()));
    expect(find.text('Loading'), findsOneWidget);

    // Wait for the background isolate to finish
    final msg = await completer.future.timeout(const Duration(seconds: 10));
    expect(msg, equals('success'));
  });
}
