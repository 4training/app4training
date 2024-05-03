import 'package:app4training/background/background_scheduler.dart';
import 'package:app4training/data/globals.dart';
import 'package:app4training/data/updates.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// As there is no easy way to test Workmanager (is there?), this class can be
/// used instead to verify correct behavior
///
/// Use this to test all places where BackgroundScheduler.schedule() gets called
class TestBackgroundScheduler extends BackgroundScheduler {
  /// Same implementation as the real BackgroundScheduler.schedule() function,
  /// just without the Workmanager calls
  @override
  Future<void> schedule() async {
    Duration? interval = ref.read(checkFrequencyProvider).getDuration();
    if (interval == null) {
      state = false;
      return;
    }
    state = true;
  }
}

void main() {
  test('Testing TestBackgroundScheduler', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final ref = ProviderContainer(overrides: [
      backgroundSchedulerProvider.overrideWith(() => TestBackgroundScheduler()),
      sharedPrefsProvider.overrideWith((ref) => prefs)
    ]);

    expect(ref.read(backgroundSchedulerProvider), false);
    await ref.read(backgroundSchedulerProvider.notifier).schedule();
    expect(ref.read(backgroundSchedulerProvider), true);
    ref.read(checkFrequencyProvider.notifier).setCheckFrequency("never");
    await ref.read(backgroundSchedulerProvider.notifier).schedule();
    expect(ref.read(backgroundSchedulerProvider), false);
  });
}
