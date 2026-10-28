import 'package:app4training/features/perf/perf_logger.dart';
import 'package:flutter/widgets.dart';

/// Records which kind of screen is shown, so jank frames in the perf logs
/// can be attributed to a screen (e.g. a worksheet vs. the settings).
///
/// Only the first route segment is recorded: `/view/Healing/de` becomes
/// `view` - page names and language codes stay out of the logs.
/// `depth` is the number of screens on the stack (hidden ones included).
class PerfNavigatorObserver extends NavigatorObserver {
  int _depth = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) _depth++;
    _recordScreen(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) _depth--;
    _recordScreen(previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) _depth--;
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _recordScreen(newRoute);
  }

  void _recordScreen(Route<dynamic>? route) {
    final String? name = route?.settings.name;
    if (name == null) return;
    final List<String> segments = name.split('/');
    final String screen = segments.length > 1 ? segments[1] : name;
    PerfLogger.event(
      'screen',
      data: {'screen': screen.isEmpty ? '/' : screen, 'depth': _depth},
    );
  }
}
