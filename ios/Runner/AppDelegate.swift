import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerStorageChannel(engineBridge.pluginRegistry)
  }

  /// Key-value storage for saved games, stats and settings (UserDefaults).
  private func registerStorageChannel(_ registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "TaktikaStorage") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "taktika/storage",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard let args = call.arguments as? [String: Any],
            let key = args["key"] as? String else {
        result(FlutterError(code: "bad_args", message: "key is required", details: nil))
        return
      }
      let defaults = UserDefaults.standard
      switch call.method {
      case "read":
        result(defaults.string(forKey: key))
      case "write":
        defaults.set(args["value"] as? String, forKey: key)
        result(nil)
      case "remove":
        defaults.removeObject(forKey: key)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
