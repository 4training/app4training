import 'dart:async';

import 'package:app4training/features/perf/perf_logger.dart';
import 'package:flutter/widgets.dart';

/// Keeps the navigation stack from growing without bounds.
///
/// Every worksheet the user opens (drawer, language menu, links inside a
/// worksheet) is pushed on top of the previous one, and each hidden route
/// keeps its whole flutter_html tree alive - and rebuilds it whenever
/// something it depends on changes (dark mode, app language, content
/// updates). So once the stack is deeper than [maxDepth], the oldest route
/// is dropped: the back button still works for the most recent screens.
class RouteStackLimiter extends NavigatorObserver {
  final int maxDepth;

  /// The page routes currently on the stack, oldest first
  final List<Route<dynamic>> _routes = [];

  RouteStackLimiter({required this.maxDepth});

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // Dialogs and popup menus are short-lived and keep no page alive
    if (route is! PageRoute) return;
    _routes.add(route);
    if (_routes.length > maxDepth) {
      final Route<dynamic> oldest = _routes.first;
      // The navigator is locked while it notifies its observers
      scheduleMicrotask(() {
        if (!oldest.isActive) return;
        navigator?.removeRoute(oldest);
        // How often does that happen, i.e. users lose back history?
        PerfLogger.event('stack.trimmed');
      });
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final int index = oldRoute == null ? -1 : _routes.indexOf(oldRoute);
    if (newRoute == null) return;
    if (index == -1) {
      _routes.add(newRoute);
    } else {
      _routes[index] = newRoute;
    }
  }
}
