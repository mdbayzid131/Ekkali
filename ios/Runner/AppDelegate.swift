import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let channelName = "com.moeb26.app/screen_protector"
  private var methodChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      methodChannel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.binaryMessenger)
      methodChannel?.setMethodCallHandler { (call, result) in
        switch call.method {
        case "isScreenCaptured":
          if #available(iOS 11.0, *) {
            result(UIScreen.main.isCaptured)
          } else {
            result(false)
          }
        case "enableWakeLock":
          DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = true
          }
          result(true)
        case "disableWakeLock":
          DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = false
          }
          result(true)
        default:
          result(FlutterMethodNotImplemented)
        }
      }

      // Listen to screen recording / AirPlay capture (iOS 11+)
      if #available(iOS 11.0, *) {
        NotificationCenter.default.addObserver(
          forName: UIScreen.capturedDidChangeNotification,
          object: nil,
          queue: .main
        ) { [weak self] _ in
          let isCaptured = UIScreen.main.isCaptured
          self?.methodChannel?.invokeMethod("onScreenCapturedChanged", arguments: isCaptured)
        }
      }

      // Listen to user taking screenshot
      NotificationCenter.default.addObserver(
        forName: UIApplication.userDidTakeScreenshotNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        self?.methodChannel?.invokeMethod("onUserDidTakeScreenshot", arguments: nil)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}