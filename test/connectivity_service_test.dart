import 'package:app4training/background/background_test.dart';
import 'package:app4training/data/connectivity_service.dart';
import 'package:app4training/data/globals.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show ProviderException;

void main() {
  test('connectivityServiceProvider throws if not overridden', () {
    final ref = ProviderContainer();
    expect(
      () => ref.read(connectivityServiceProvider),
      throwsA(isA<ProviderException>()),
    );
  });

  test('FakeConnectivityService returns the controllable result', () async {
    final fake = FakeConnectivityService(unmetered: true);
    expect(await fake.isUnmetered(), true);

    fake.unmetered = false;
    expect(await fake.isUnmetered(), false);
  });

  group('isUnmeteredConnection: WiFi/ethernet count, mobile does not', () {
    test('WiFi is unmetered', () {
      expect(isUnmeteredConnection([ConnectivityResult.wifi]), true);
    });
    test('Ethernet is unmetered', () {
      expect(isUnmeteredConnection([ConnectivityResult.ethernet]), true);
    });
    test('Mobile is metered', () {
      expect(isUnmeteredConnection([ConnectivityResult.mobile]), false);
    });
    test('No connection is metered', () {
      expect(isUnmeteredConnection([ConnectivityResult.none]), false);
    });
    test('Mixed mobile + wifi is unmetered', () {
      expect(
        isUnmeteredConnection([
          ConnectivityResult.mobile,
          ConnectivityResult.wifi,
        ]),
        true,
      );
    });
    test('Empty list is metered', () {
      expect(isUnmeteredConnection([]), false);
    });
  });
}
