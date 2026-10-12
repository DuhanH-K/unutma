import Flutter
import UIKit
import UserNotifications
import os

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var adsConfigChannel: FlutterMethodChannel?
  private var appInfoChannel: FlutterMethodChannel?
  private var nativeApi: NativeUnutmaApi?
  private let reminders = IOSReminders()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let launched = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    UNUserNotificationCenter.current().delegate = reminders
    return launched
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let messenger = engineBridge.applicationRegistrar.messenger()
    let infoChannel = FlutterMethodChannel(name: "app.unutma/app-info", binaryMessenger: messenger)
    infoChannel.setMethodCallHandler { call, result in
      guard call.method == "getInfo" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String else {
        result(FlutterError(code: "metadata_unavailable", message: nil, details: nil))
        return
      }
      result(["name": name, "build": build])
    }
    appInfoChannel = infoChannel
    do {
      let api = try NativeUnutmaApi(binaryMessenger: messenger, reminders: reminders)
      UnutmaApiSetup.setUp(binaryMessenger: messenger, api: api)
      nativeApi = api
    } catch {
      Logger(subsystem: "app.unutma.mobile", category: "Startup")
        .error("Native bridge registration failed; Flutter recovery screen will be available")
    }

    let channel = FlutterMethodChannel(
      name: "app.unutma/ads-config",
      binaryMessenger: messenger
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
