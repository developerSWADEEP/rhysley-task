import 'package:flutter/services.dart';

class NativeLocationService {
  static const MethodChannel _channel = MethodChannel('native_location_channel');
  static const EventChannel _eventChannel = EventChannel('native_location_events');
  
  static Future<bool> startService() async {
    try {
      final result = await _channel.invokeMethod('startNativeLocationService');
      print("✅ Native location service started: $result");
      return result == true;
    } catch (e) {
      print("❌ Failed to start native location service: $e");
      return false;
    }
  }
  
  static Future<bool> stopService() async {
    try {
      final result = await _channel.invokeMethod('stopNativeLocationService');
      print("✅ Native location service stopped: $result");
      return result == true;
    } catch (e) {
      print("❌ Failed to stop native location service: $e");
      return false;
    }
  }
  
  static Future<bool> isServiceRunning() async {
    try {
      final result = await _channel.invokeMethod('isNativeServiceRunning');
      return result == true;
    } catch (e) {
      print("❌ Failed to check native service status: $e");
      return false;
    }
  }
  
  // Listen to location updates from native service using EventChannel
  static Stream<Map<String, dynamic>> get locationStream {
    return _eventChannel.receiveBroadcastStream().map((data) {
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return <String, dynamic>{};
    });
  }
  
  // Enhanced method to handle background location updates
  static Stream<Map<String, dynamic>> get backgroundLocationStream {
    return _eventChannel.receiveBroadcastStream().map((data) {
      if (data is Map) {
        final locationData = Map<String, dynamic>.from(data);
        
        // Log background location updates
        if (locationData.containsKey('latitude') && locationData.containsKey('longitude')) {
          print("📍 Background location update received:");
          print("📍 Lat: ${locationData['latitude']}, Lng: ${locationData['longitude']}");
          print("📍 Accuracy: ${locationData['accuracy']}m");
          print("📍 Significant change: ${locationData['isSignificantChange']}");
          print("📍 Source: ${locationData['source']}");
        }
        
        return locationData;
      }
      return <String, dynamic>{};
    });
  }
}
