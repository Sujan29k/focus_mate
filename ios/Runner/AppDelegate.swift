import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Register ScreenTime channel for iOS 15+ (after adding Swift files to Xcode)
    if #available(iOS 15.0, *) {
      if let registrar = self.registrar(forPlugin: "ScreenTimeChannel") {
        ScreenTimeChannel.register(with: registrar)
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
