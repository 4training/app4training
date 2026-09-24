import 'package:connectivity_plus/connectivity_plus.dart';

/// Abstraction over connectivity so both the foreground and the background
/// isolate can ask "are we on an unmetered connection right now?" without a
/// [BuildContext], and so tests can inject a controllable result.
///
/// See [connectivityServiceProvider] (a MustOverrideProvider): the real impl is
/// wired up in `main.dart` and in `backgroundMain()`, and tests inject
/// [FakeConnectivityService].
abstract interface class ConnectivityService {
  /// Whether the current connection is unmetered (WiFi or ethernet), i.e.
  /// downloading won't burn the user's mobile data.
  ///
  /// This is the honest predicate behind [AutomaticUpdates.onlyOnWifi]: the
  /// user's intent is "don't use mobile data", so ethernet counts as fine too.
  Future<bool> isUnmetered();
}

/// Whether any of the currently active connections is unmetered (WiFi or
/// ethernet). Split out from [ConnectivityServiceImpl] so the mapping can be
/// unit-tested without touching a platform channel.
bool isUnmeteredConnection(List<ConnectivityResult> results) {
  return results.any(
    (r) => r == ConnectivityResult.wifi || r == ConnectivityResult.ethernet,
  );
}

/// Real [ConnectivityService] backed by the `connectivity_plus` package.
class ConnectivityServiceImpl implements ConnectivityService {
  final Connectivity _connectivity;

  ConnectivityServiceImpl({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  @override
  Future<bool> isUnmetered() async {
    return isUnmeteredConnection(await _connectivity.checkConnectivity());
  }
}
