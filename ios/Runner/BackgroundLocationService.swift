import Foundation
import CoreLocation
import UIKit
import Flutter

@objc(BackgroundLocationService)
public class BackgroundLocationService: NSObject, CLLocationManagerDelegate {
    private var locationManager: CLLocationManager?
    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?
    private var isServiceRunning = false
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = .invalid
    
    // Configuration for significant location changes
    private let significantLocationChangeThreshold: CLLocationDistance = 100 // meters
    private var lastKnownLocation: CLLocation?
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.distanceFilter = significantLocationChangeThreshold
        
        // Configure for background location updates
        if #available(iOS 9.0, *) {
            locationManager?.allowsBackgroundLocationUpdates = true
        }
        locationManager?.pausesLocationUpdatesAutomatically = false
    }
    
    func setMethodChannel(_ channel: FlutterMethodChannel) {
        methodChannel = channel
    }
    
    func setEventChannel(_ channel: FlutterEventChannel) {
        eventChannel = channel
    }
    
    func setEventSink(_ sink: FlutterEventSink?) {
        eventSink = sink
    }
    
    @objc func startService() -> Bool {
        print("🚀 BackgroundLocationService: Starting service")
        
        guard let locationManager = locationManager else {
            print("❌ BackgroundLocationService: Location manager not initialized")
            return false
        }
        
        // Check authorization status
        let authStatus = locationManager.authorizationStatus
        print("🔐 BackgroundLocationService: Authorization status: \(authStatus.rawValue)")
        
        switch authStatus {
        case .notDetermined:
            print("🔐 BackgroundLocationService: Requesting location permission")
            locationManager.requestAlwaysAuthorization()
            return false
            
        case .denied, .restricted:
            print("❌ BackgroundLocationService: Location permission denied")
            return false
            
        case .authorizedWhenInUse:
            print("⚠️ BackgroundLocationService: Only 'when in use' permission granted, requesting 'always' permission")
            locationManager.requestAlwaysAuthorization()
            return false
            
        case .authorizedAlways:
            print("✅ BackgroundLocationService: Always location permission granted")
            break
            
        @unknown default:
            print("❌ BackgroundLocationService: Unknown authorization status")
            return false
        }
        
        // Check if location services are enabled
        guard CLLocationManager.locationServicesEnabled() else {
            print("❌ BackgroundLocationService: Location services are disabled")
            return false
        }
        
        // Start significant location change monitoring (works even when app is killed)
        locationManager.startMonitoringSignificantLocationChanges()
        print("✅ BackgroundLocationService: Started significant location change monitoring")
        
        // Also start standard location updates for more frequent updates when app is active
        locationManager.startUpdatingLocation()
        print("✅ BackgroundLocationService: Started standard location updates")
        
        isServiceRunning = true
        
        // Send initial status to Flutter
        sendLocationUpdate(["status": "started", "message": "Background location service started"])
        
        return true
    }
    
    @objc func stopService() -> Bool {
        print("🛑 BackgroundLocationService: Stopping service")
        
        guard let locationManager = locationManager else {
            return false
        }
        
        locationManager.stopMonitoringSignificantLocationChanges()
        locationManager.stopUpdatingLocation()
        
        isServiceRunning = false
        
        // Send status to Flutter
        sendLocationUpdate(["status": "stopped", "message": "Background location service stopped"])
        
        return true
    }
    
    @objc func isServiceRunning() -> Bool {
        return isServiceRunning
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        print("📍 BackgroundLocationService: Received location update")
        print("📍 Lat: \(location.coordinate.latitude), Lng: \(location.coordinate.longitude)")
        print("📍 Accuracy: \(location.horizontalAccuracy)m")
        print("📍 Timestamp: \(location.timestamp)")
        
        // Check if this is a significant location change
        let isSignificantChange = isSignificantLocationChange(location)
        print("📍 Significant change: \(isSignificantChange)")
        
        // Always send location updates, but mark significant changes
        let locationData: [String: Any] = [
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "accuracy": location.horizontalAccuracy,
            "altitude": location.altitude,
            "speed": location.speed,
            "heading": location.course,
            "timestamp": location.timestamp.timeIntervalSince1970 * 1000, // Convert to milliseconds
            "isSignificantChange": isSignificantChange,
            "source": "background_service"
        ]
        
        sendLocationUpdate(locationData)
        
        // Update last known location
        lastKnownLocation = location
        
        // Send to server if this is a significant change or if we haven't sent in a while
        if isSignificantChange {
            sendLocationToServer(location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ BackgroundLocationService: Location error: \(error.localizedDescription)")
        
        let errorData: [String: Any] = [
            "error": error.localizedDescription,
            "status": "error"
        ]
        
        sendLocationUpdate(errorData)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("🔐 BackgroundLocationService: Authorization status changed to: \(status.rawValue)")
        
        let statusData: [String: Any] = [
            "authorizationStatus": status.rawValue,
            "status": "authorization_changed"
        ]
        
        sendLocationUpdate(statusData)
        
        // If we now have always authorization, start the service
        if status == .authorizedAlways && !isServiceRunning {
            _ = startService()
        }
    }
    
    // MARK: - Helper Methods
    
    private func isSignificantLocationChange(_ location: CLLocation) -> Bool {
        guard let lastLocation = lastKnownLocation else {
            return true // First location is always significant
        }
        
        let distance = location.distance(from: lastLocation)
        return distance >= significantLocationChangeThreshold
    }
    
    private func sendLocationUpdate(_ data: [String: Any]) {
        guard let eventSink = eventSink else {
            print("⚠️ BackgroundLocationService: No event sink available")
            return
        }
        
        DispatchQueue.main.async {
            eventSink(data)
        }
    }
    
    private func sendLocationToServer(_ location: CLLocation) {
        // This would typically make an HTTP request to your server
        // For now, we'll just log it
        print("🌐 BackgroundLocationService: Sending location to server")
        print("🌐 Lat: \(location.coordinate.latitude), Lng: \(location.coordinate.longitude)")
        
        // You can implement actual server communication here
        // This could use URLSession or your preferred networking library
    }
    
    // MARK: - Background Task Management
    
    private func beginBackgroundTask() {
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "LocationTracking") {
            self.endBackgroundTask()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTaskIdentifier != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
            backgroundTaskIdentifier = .invalid
        }
    }
}

// MARK: - Flutter Plugin Integration

@objc(BackgroundLocationPlugin)
public class BackgroundLocationPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var backgroundLocationService: BackgroundLocationService?
    private var eventChannel: FlutterEventChannel?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "native_location_channel", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "native_location_events", binaryMessenger: registrar.messenger())
        
        let instance = BackgroundLocationPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)
        
        instance.eventChannel = eventChannel
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startNativeLocationService":
            if backgroundLocationService == nil {
                backgroundLocationService = BackgroundLocationService()
            }
            
            let success = backgroundLocationService?.startService() ?? false
            result(success)
            
        case "stopNativeLocationService":
            let success = backgroundLocationService?.stopService() ?? false
            result(success)
            
        case "isNativeServiceRunning":
            let isRunning = backgroundLocationService?.isServiceRunning() ?? false
            result(isRunning)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - FlutterStreamHandler
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        if backgroundLocationService == nil {
            backgroundLocationService = BackgroundLocationService()
        }
        
        backgroundLocationService?.setEventSink(events)
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        backgroundLocationService?.setEventSink(nil)
        return nil
    }
}
