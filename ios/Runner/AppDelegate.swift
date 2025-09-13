import Flutter
import UIKit
import CoreLocation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // Register our custom background location plugin
    if let controller = window?.rootViewController as? FlutterViewController {
      BackgroundLocationPlugin.register(with: registrar(for: controller)!)
    }
    
    GeneratedPluginRegistrant.register(with: self)
    
    // Configure background app refresh
    if #available(iOS 13.0, *) {
      // Enable background app refresh
      UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Handle background app refresh
  override func application(
    _ application: UIApplication,
    performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    print("🔄 BackgroundLocationService: Background fetch triggered")
    
    // You can perform location-related tasks here
    // For example, check if location service is still running
    
    completionHandler(.newData)
  }
  
  // Handle location updates when app is launched from background
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    print("📱 BackgroundLocationService: Received remote notification")
    completionHandler(.newData)
  }
}
