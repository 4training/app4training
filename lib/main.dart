import 'package:app4training/data/connectivity_service.dart';
import 'dart:async';

import 'package:app4training/data/language_downloader.dart';
import 'package:app4training/features/perf/perf_logger.dart';
import 'package:app4training/l10n/generated/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:file/local.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app4training/routes/routes.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'background/background_task.dart';
import 'data/app_language.dart';
import 'data/globals.dart';
import 'design/theme.dart';

/// Installs a global [FlutterError.onError] wrapper that suppresses the
/// known non-fatal framework assertions produced by `flutter_html` /
/// `flutter_html_table` when rendering pages that contain tables, and
/// forwards everything else unchanged to the previously-installed
/// handler (typically [FlutterError.presentError]).
///
/// Four assertion variants have been observed in the wild, all
/// originating from the `LayoutBuilder` / `LayoutGrid` / `WidgetSpan`
/// composition that `TableHtmlExtension.build` constructs for `<table>`
/// rendering:
///
///   1. Paint-time `RenderBox was not laid out` — fires from
///      `PipelineOwner.flushPaint` → `RenderCSSBox.paint` →
///      `RenderDecoratedBox.paint` → `RenderBox.size`. Stack contains
///      `flutter_html/` and `flutter_layout_grid/` frames.
///
///   2. Semantics-pass `RenderBox was not laid out` — fires from
///      `PipelineOwner.flushSemantics` →
///      `_SemanticsGeometry.computeChildGeometry` →
///      `RenderBox.semanticBounds` → `RenderBox.size`. Reported via
///      `SchedulerBinding._invokeFrameCallback` with
///      `library: 'scheduler library'`. The stack is **pure framework
///      code** with no package frames, because the semantics walk
///      traverses the `_RenderObjectSemantics` tree directly without
///      going through widget code — so matching on package paths alone
///      would miss this variant.
///
///   3. Layout-time `RenderBox.size accessed in ...computeDryBaseline`
///      — fires from `RenderParagraph.performLayout` →
///      `layoutInlineChildren` → child `performLayout` reading `.size`
///      during a dry-baseline computation. Stack contains
///      `flutter_html/src/css_box_widget.dart` frames.
///
///   4. Layout-time `'child!.hasSize' is not true` — fires from
///      `RenderAligningShiftedBox.alignChild` while laying out a
///      `Container` constructed in `flutter_html_table.dart:261`.
///      Stack contains `flutter_html/` and `flutter_layout_grid/`
///      frames.
///
/// All four are non-fatal: the page renders, users can interact
/// normally, selection still works outside tables. They flood logs
/// (hundreds per page load) which drowns out any real errors, which is
/// why we filter them.
///
/// Why this lives here and not in the widget layer:
///   1. The assertions are not reproducible in `flutter_test`, even
///      with `tester.ensureSemantics()` + a phone-sized surface, so we
///      cannot regression-test a widget-level fix;
///   2. The root cause is inside third-party package code
///      (`flutter_html_table` 3.0.0). Wrapping tables in
///      `SelectionContainer.disabled` (mirroring Flutter's own
///      `raw_tooltip.dart:813-815` pattern) did not help and also
///      broke text selection across the whole page;
///   3. The real fix is a newer upstream release. Until then this
///      filter keeps the logs usable.
///
/// Matching strategy — an error is suppressed only if BOTH:
///   (a) the exception message contains one of the four known
///       signatures (`"RenderBox was not laid out"`, `"computeDryBaseline"`,
///       `"renderBoxDoingDryBaseline"`, or `"'child!.hasSize'"`), AND
///   (b) the stack either passes through `flutter_html/` or
///       `flutter_layout_grid/` package code (covers variants 1, 3, 4)
///       OR contains `"flushSemantics"` (covers variant 2, whose stack
///       is entirely framework code).
///
/// Any error that doesn't satisfy BOTH conditions is forwarded to the
/// previous handler unchanged, so unrelated regressions are not masked.
///
/// On the first suppression per app run we emit a single breadcrumb via
/// [debugPrint] so developers inspecting logs can see that the filter
/// is active. Subsequent suppressions are silent to avoid log spam.
///
/// See also: `docs/in_progress_notes/flushSemantics_assertion.md`
/// for the full investigation history.
/// Including the diagnostic logging session that identified all four
/// variants.
void _installHtmlTableSemanticsFilter() {
  final FlutterExceptionHandler? previousHandler = FlutterError.onError;
  var suppressedBreadcrumbEmitted = false;
  FlutterError.onError = (FlutterErrorDetails details) {
    if (_isKnownHtmlTableAssertion(details)) {
      if (!suppressedBreadcrumbEmitted) {
        suppressedBreadcrumbEmitted = true;
        debugPrint(
          'Suppressing known flutter_html_table non-fatal framework '
          'assertions (see Task Progress.md §5 and main.dart '
          '_installHtmlTableSemanticsFilter for details). Subsequent '
          'suppressions are silent.',
        );
      }
      return;
    }
    if (previousHandler != null) {
      previousHandler(details);
    } else {
      FlutterError.presentError(details);
    }
  };
}

/// Does [details] match one of the four known, non-fatal
/// `flutter_html_table` assertions? See [_installHtmlTableSemanticsFilter]
/// for the matching strategy.
bool _isKnownHtmlTableAssertion(FlutterErrorDetails details) {
  final String exceptionText = details.exception.toString();
  final bool exceptionMatchesKnownSignature =
      exceptionText.contains('RenderBox was not laid out') ||
      exceptionText.contains('computeDryBaseline') ||
      exceptionText.contains('renderBoxDoingDryBaseline') ||
      exceptionText.contains("'child!.hasSize'");
  // Stringifying the stack is by far the expensive half of this check, and
  // these assertions fire hundreds of times per page load in debug/profile
  // builds - so only pay for it once the cheap message check has matched.
  if (!exceptionMatchesKnownSignature) return false;
  final String stackText = details.stack?.toString() ?? '';
  return stackText.contains('flutter_html/') ||
      stackText.contains('flutter_layout_grid/') ||
      stackText.contains('flushSemantics');
}

void main() async {
  PerfLogger.markAppStart();
  WidgetsFlutterBinding.ensureInitialized();
  _installHtmlTableSemanticsFilter();
  // None of these three depend on each other, so don't pay for three
  // sequential platform channel round trips - the native splash screen is up
  // for all of it, without a single Flutter frame rendered yet.
  final (prefs, packageInfo, appDocsDir) = await PerfLogger.span(
    'main.platformChannels',
    () =>
        (
          SharedPreferences.getInstance(),
          PackageInfo.fromPlatform(),
          getApplicationDocumentsDirectory(),
        ).wait,
  );
  PerfLogger.start(
    fileSystem: const LocalFileSystem(),
    directory: p.join(appDocsDir.path, 'perf_sessions'),
  );
  unawaited(PerfLogger.logDeviceAndApp(packageInfo));
  final languageDownloader = LanguageDownloaderImpl(
    root: appDocsDir.path,
    dio: Dio(),
    fileSystem: const LocalFileSystem(),
  );

  // Register the isolate entry point for our background task. Periodic
  // scheduling itself is owned by BackgroundScheduler.schedule(), triggered by
  // startup / onboarding / the check-frequency setting.
  await Workmanager().initialize(backgroundTask);

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        packageInfoProvider.overrideWithValue(packageInfo),
        languageDownloaderProvider.overrideWithValue(languageDownloader),
        connectivityServiceProvider.overrideWithValue(
          ConnectivityServiceImpl(),
        ),
      ],
      child: const App4Training(),
    ),
  );
  PerfLogger.attachToApp();
}

class App4Training extends ConsumerWidget {
  const App4Training({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLanguage appLanguage = ref.watch(appLanguageProvider);
    return MaterialApp(
      title: Globals.appTitle,
      darkTheme: darkTheme,
      theme: lightTheme,
      themeMode: ThemeMode.system,
      initialRoute: '/',
      onGenerateRoute: (settings) => generateRoutes(settings),
      locale: appLanguage.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      scaffoldMessengerKey: ref.watch(scaffoldMessengerKeyProvider),
    );
  }
}
