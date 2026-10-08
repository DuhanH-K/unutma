import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var adsConfigChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "app.unutma/ads-config",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "getConfig" else {
        result(FlutterMethodNotImplemented)
        return
      }
      let info = Bundle.main.infoDictionary ?? [:]
      let enabled = (info["UNUTMAAdsEnabled"] as? String) == "YES"
      let testAds = (info["UNUTMAAdMobTestAds"] as? String) == "YES"
      result([
        "enabled": enabled,
        "interstitialId": info["UNUTMAAdMobInterstitialId"] as? String ?? "",
        "bannerId": info["UNUTMAAdMobBannerId"] as? String ?? "",
        "testAds": testAds,
      ])
    }
    adsConfigChannel = channel
  }
}
