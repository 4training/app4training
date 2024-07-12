import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The state indicates whether our background task is scheduled or not.
/// The schedule() method gets called
/// - on/after third onboarding step (where user configures automatic updates)
/// - by StartupPage during normal app startup
/// - when the user changes the check frequency setting
class BackgroundScheduler extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  /// Schedule our background task according to the settings
  /// If user doesn't want automatic updates: nothing happens
  /// (and state of the provider will be false)
  ///
  /// Make sure TestBackgroundScheduler.schedule() has the same logic
  Future<void> schedule() async {
    /* TODO Enable this with version 0.9
    debugPrint('Cancelling all currently scheduled background tasks');
    await Workmanager().cancelByUniqueName('backgroundTask');
    Duration? interval = ref.read(checkFrequencyProvider).getDuration();
    if (interval == null) {
      state = false;
      return;
    }
    await Workmanager().registerPeriodicTask('backgroundTask', 'backgroundTask',
        constraints: Constraints(networkType: NetworkType.connected),
        initialDelay: interval ~/ 2);
    debugPrint('Succesfully scheduled the background task: $interval');
    state = true;
    */
  }
}

/// Our central access to scheduling the background task.
/// The state of it indicates whether the background task is scheduled or not.
final backgroundSchedulerProvider =
    NotifierProvider<BackgroundScheduler, bool>(() {
  return BackgroundScheduler();
});
