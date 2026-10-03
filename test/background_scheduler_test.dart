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
  /// How often did we (would we have) registered a periodic task?
  int registerCalls = 0;

  /// How often did we cancel the previously scheduled task?
  int cancelCalls = 0;

  /// Same implementation as the real BackgroundScheduler.schedule() function,
  /// just without the Workmanager calls
  @override
  Future<void> schedule() async {
    cancelCalls++;
    Duration? interval = ref.read(checkFrequencyProvider).getDuration();
    if (interval == null) {
      state = false;
      return;
    }
    registerCalls++;
    state = true;
  }
}

void main() {
  Future<ProviderContainer> createContainer(String? checkFrequency) async {
    SharedPreferences.setMockInitialValues(
      checkFrequency == null ? {} : {'checkFrequency': checkFrequency},
    );
    final prefs = await SharedPreferences.getInstance();
    return ProviderContainer(
      overrides: [
        backgroundSchedulerProvider.overrideWith(
          () => TestBackgroundScheduler(),
        ),
        sharedPrefsProvider.overrideWith((ref) => prefs),
      ],
    );
  }

  test('Provider state is false before scheduling', () async {
    final ref = await createContainer(null);
    expect(ref.read(backgroundSchedulerProvider), false);
  });

  test('CheckFrequency.never: nothing scheduled, state stays false', () async {
    final ref = await createContainer('never');
    final scheduler =
        ref.read(backgroundSchedulerProvider.notifier)
            as TestBackgroundScheduler;

    await scheduler.schedule();

    expect(ref.read(backgroundSchedulerProvider), false);
    expect(scheduler.registerCalls, 0);
  });

  test('Each real frequency schedules the task and sets state true', () async {
    for (final frequency in ['daily', 'weekly', 'monthly', 'testinterval']) {
      final ref = await createContainer(frequency);
      final scheduler =
          ref.read(backgroundSchedulerProvider.notifier)
              as TestBackgroundScheduler;

      await scheduler.schedule();

      expect(
        ref.read(backgroundSchedulerProvider),
        true,
        reason: 'state should be true for $frequency',
      );
      expect(
        scheduler.registerCalls,
        1,
        reason: 'one periodic task should be registered for $frequency',
      );
    }
  });

  test('Re-scheduling cancels the previous registration first', () async {
    final ref = await createContainer('weekly');
    final scheduler =
        ref.read(backgroundSchedulerProvider.notifier)
            as TestBackgroundScheduler;

    await scheduler.schedule();
    await scheduler.schedule();

    // Every schedule() call cancels the prior registration before registering
    expect(scheduler.cancelCalls, 2);
    expect(scheduler.registerCalls, 2);
    expect(ref.read(backgroundSchedulerProvider), true);
  });

  test('Switching to never after a real frequency cancels the task', () async {
    final ref = await createContainer('weekly');
    final scheduler =
        ref.read(backgroundSchedulerProvider.notifier)
            as TestBackgroundScheduler;

    await scheduler.schedule();
    expect(ref.read(backgroundSchedulerProvider), true);

    ref.read(checkFrequencyProvider.notifier).setCheckFrequency('never');
    await scheduler.schedule();

    expect(ref.read(backgroundSchedulerProvider), false);
  });
}
