import 'package:app4training/data/globals.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/features/perf/perf_export_section.dart';
import 'package:app4training/features/perf/perf_logger.dart';
import 'package:app4training/features/share/share_service.dart';
import 'package:file/memory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:share_plus/share_plus.dart';

class MockShareService extends Mock implements ShareService {}

class TestPerfExportSection extends ConsumerWidget {
  const TestPerfExportSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      scaffoldMessengerKey: ref.read(scaffoldMessengerKeyProvider),
      home: const Scaffold(body: PerfExportSection()),
    );
  }
}

void main() {
  tearDown(PerfLogger.reset);

  ProviderContainer makeContainer(MockShareService shareService) {
    return ProviderContainer(
      overrides: [
        shareProvider.overrideWithValue(shareService),
        diskUsageProvider.overrideWith((ref) async => 12345),
        countDownloadedLanguagesProvider.overrideWith((ref) => 3),
      ],
    );
  }

  testWidgets('renders nothing in normal builds', (WidgetTester tester) async {
    // In `flutter test` the dart-define is unset, so enabled is false
    final container = makeContainer(MockShareService());
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TestPerfExportSection(),
      ),
    );

    expect(find.text('Performance profiling'), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing);
  });

  testWidgets('shows status and exports via the share sheet', (
    WidgetTester tester,
  ) async {
    final fileSystem = MemoryFileSystem();
    PerfLogger.enabled = true;
    PerfLogger.start(
      fileSystem: fileSystem,
      directory: '/perf_sessions',
      now: () => DateTime(2026, 8, 27, 15, 0, 0),
      autoFlush: false,
    );
    await PerfLogger.flush(); // one session on disk

    final shareService = MockShareService();
    when(() => shareService.shareFile(any())).thenAnswer(
      (_) async => const ShareResult('ok', ShareResultStatus.success),
    );
    final container = makeContainer(shareService);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TestPerfExportSection(),
      ),
    );
    await tester.pump(); // let the session-count FutureBuilder resolve

    expect(find.text('Performance profiling'), findsOneWidget);
    expect(find.text('Logging active'), findsOneWidget);
    expect(find.text('1 sessions recorded'), findsOneWidget);

    await tester.tap(find.text('Export profiling data'));
    await tester.pumpAndSettle();

    final String sharedPath =
        verify(() => shareService.shareFile(captureAny())).captured.single
            as String;
    expect(sharedPath, contains('app4training-perf-2026-08-27_15-00-00'));
    expect(sharedPath, endsWith('.jsonl.gz'));
    // The exported file really exists on the (memory) file system
    expect(await fileSystem.file(sharedPath).exists(), true);
    // The appState context was recorded with the export
    final exported =
        await fileSystem
            .file('/perf_sessions/session-2026-08-27_15-00-00-000.jsonl')
            .readAsString();
    expect(exported, contains('"downloadedLanguages":3'));
    expect(exported, contains('"contentSizeKB":12345'));
  });
}
