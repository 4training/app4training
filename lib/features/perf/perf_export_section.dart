import 'package:app4training/data/globals.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/features/perf/perf_logger.dart';
import 'package:app4training/features/share/share_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings section for instrumented tester builds (see [kPerfLoggingEnabled]):
/// shows that performance logging is active and offers to export all recorded
/// sessions as one gzipped file through the system share sheet.
///
/// Renders nothing in normal builds. Strings are deliberately not localized -
/// this UI only exists in builds we hand to testers ourselves.
class PerfExportSection extends ConsumerStatefulWidget {
  const PerfExportSection({super.key});

  @override
  ConsumerState<PerfExportSection> createState() => _PerfExportSectionState();
}

class _PerfExportSectionState extends ConsumerState<PerfExportSection> {
  bool _exporting = false;

  Future<void> _export() async {
    setState(() => _exporting = true);
    final ScaffoldMessengerState messenger = ref.read(
      scaffoldMessengerProvider,
    );
    try {
      // Log the app state context right before exporting: language count and
      // disk usage put the timings in perspective. Computing the disk usage
      // walks all language directories, which is exactly why it must not
      // happen at startup - here the user explicitly asked for it.
      PerfLogger.event(
        'appState',
        data: {
          'downloadedLanguages': ref.read(countDownloadedLanguagesProvider),
          'contentSizeKB': await ref.read(diskUsageProvider.future),
        },
      );
      final String? path = await PerfLogger.exportAll();
      if (!mounted) return;
      if (path == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('No profiling data to export')),
        );
      } else {
        await ref.read(shareProvider).shareFile(path);
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!PerfLogger.enabled) return const SizedBox.shrink();
    return Column(
      children: [
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.topLeft,
          child: Text(
            'Performance profiling',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Logging active',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            FutureBuilder<int>(
              future: PerfLogger.countStoredSessions(),
              builder:
                  (context, snapshot) => Text(
                    '${snapshot.data ?? '…'} sessions recorded',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: _exporting ? null : _export,
              child: const Text('Export profiling data'),
            ),
          ],
        ),
      ],
    );
  }
}
