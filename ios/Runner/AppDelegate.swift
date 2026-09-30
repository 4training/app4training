import Flutter
import UIKit
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Register plugins in the headless engine that runs the background task
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    // Must match BackgroundScheduler's unique name and Info.plist's
    // BGTaskSchedulerPermittedIdentifiers. iOS reschedules at this fixed
    // frequency (daily, the shortest CheckFrequency) after the first run.
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: "backgroundTask",
      frequency: NSNumber(value: 24 * 60 * 60)
    )
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
