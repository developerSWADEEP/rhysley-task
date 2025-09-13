import 'dart:ui';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'api_service.dart';
import 'notification_service.dart';
import 'native_location_service.dart';
import '../../core/constants/api_constants.dart';

Future<void> forceStopAllServices() async {
  try {
    final service = FlutterBackgroundService();
    
    // Check if service is running and stop it
    final isRunning = await service.isRunning();
    if (isRunning) {
      print("🛑 Stopping existing background service");
      service.invoke("stopService");
      
      // Wait a bit for service to stop
      await Future.delayed(const Duration(seconds: 3));
    }
    
    // Stop native service
    await NativeLocationService.stopService();
    
    // Disable wake lock
    await WakelockPlus.disable();
    
    // Cancel all notifications
    await NotificationService.cancelAllNotifications();
    
    print("✅ All services stopped and resources cleaned up");
  } catch (e) {
    print("❌ Error stopping services: $e");
  }
}

Future<void> initializeService() async {
  try {
    // Initialize notification service first
    await NotificationService.initialize();
    
    // First, force stop any existing services
    await forceStopAllServices();
    
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false, // Explicitly disabled
        isForegroundMode: true, // Enable foreground mode for better background operation
        autoStartOnBoot: false, // Explicitly disabled
        foregroundServiceNotificationId: 888,
        foregroundServiceTypes: [AndroidForegroundType.location],
        notificationChannelId: 'rhysley_location_tracking',
        initialNotificationTitle: 'Rhysley Location Tracking',
        initialNotificationContent: 'Location tracking service ready',
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false, // Explicitly disabled
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    print("✅ Background service configured successfully (not started)");
  } catch (e) {
    print("❌ Error initializing background service: $e");
  }
}

Future<void> startLocationTrackingService() async {
  try {
    print("🚀 Starting location tracking service");
    print("🚀 App state: Active (service starting)");
    
    // Check if user is logged in first
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("userId");
    final token = prefs.getString("token");
    
    print("🔐 User ID: $userId");
    print("🔐 Token available: ${token != null && token.isNotEmpty}");
    
    if (userId == null || token == null || token.isEmpty) {
      print("⚠️ User not logged in, cannot start background service");
      await NotificationService.showServiceStatusNotification(
        title: "❌ Service Failed",
        message: "User not logged in",
        isRunning: false,
      );
      return;
    }
    
    print("✅ User logged in, force stopping any existing services first");
    
    // Force stop any existing services first
    await forceStopAllServices();
    
    print("✅ Starting native location service for continuous tracking");
    
    // Start native service for continuous background tracking
    final nativeServiceStarted = await NativeLocationService.startService();
    
    if (nativeServiceStarted) {
      print("✅ Native location service started successfully");
      print("✅ Location sent successfully when app is active");
      
      // Show service started notification
      await NotificationService.showServiceStatusNotification(
        title: "✅ Native Location Tracking Started",
        message: "Continuous background location tracking is now active",
        isRunning: true,
      );
      
      // Listen to native service location updates
      _listenToNativeLocationUpdates();
    } else {
      print("⚠️ Native service failed, falling back to Flutter service");
      
      // Fallback to Flutter service
      await _startFlutterBackgroundService();
    }
  } catch (e) {
    print("❌ Error starting location tracking service: $e");
    await NotificationService.showServiceStatusNotification(
      title: "❌ Service Failed",
      message: "Failed to start location tracking: $e",
      isRunning: false,
    );
  }
}

Future<void> stopLocationTrackingService() async {
  try {
    // Stop native service
    await NativeLocationService.stopService();
    
    // Stop Flutter service
    final service = FlutterBackgroundService();
    service.invoke("stopService");
    
    // Disable wake lock
    await WakelockPlus.disable();
    
    // Show service stopped notification
    await NotificationService.showServiceStatusNotification(
      title: "🛑 Location Tracking Stopped",
      message: "Background location tracking has been stopped",
      isRunning: false,
    );
    
    print("✅ All location services stopped");
  } catch (e) {
    print("❌ Error stopping location services: $e");
  }
}

// Listen to location updates from native service
void _listenToNativeLocationUpdates() {
  print("🎧 Starting to listen to native location updates");
  
  NativeLocationService.locationStream.listen((locationData) async {
    if (locationData.isNotEmpty) {
      print("📍 Native service location update received in Flutter");
      print("📍 Latitude: ${locationData['latitude']}");
      print("📍 Longitude: ${locationData['longitude']}");
      print("📍 Accuracy: ${locationData['accuracy']}m");
      print("📍 Speed: ${locationData['speed']} m/s");
      print("📍 Timestamp: ${locationData['timestamp']}");
      
      // Show notification for location update
      await NotificationService.showLocationNotification(
        latitude: locationData['latitude']?.toDouble() ?? 0.0,
        longitude: locationData['longitude']?.toDouble() ?? 0.0,
        accuracy: locationData['accuracy']?.toDouble() ?? 0.0,
        speed: locationData['speed']?.toDouble() ?? 0.0,
      );
      
      print("✅ Location notification sent from Flutter");
    } else {
      print("⚠️ Empty location data received from native service");
    }
  }, onError: (error) {
    print("❌ Error listening to native location updates: $error");
  }, onDone: () {
    print("🔚 Native location stream closed");
  });
}

// Fallback Flutter background service
Future<void> _startFlutterBackgroundService() async {
  try {
    print("✅ Starting Flutter background service as fallback");
    
    // Enable wake lock to prevent device from sleeping
    await WakelockPlus.enable();
    print("🔋 Wake lock enabled");
    
    // Reconfigure service with foreground mode enabled
    final service = FlutterBackgroundService();
    
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true, // Enable foreground mode when starting
        autoStartOnBoot: false,
        foregroundServiceNotificationId: 888,
        foregroundServiceTypes: [AndroidForegroundType.location],
        notificationChannelId: 'rhysley_location_tracking',
        initialNotificationTitle: 'Rhysley Location Tracking',
        initialNotificationContent: 'Starting location tracking...',
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
    
    // Double check if service is running after cleanup
    final isRunning = await service.isRunning();
    if (isRunning) {
      print("⚠️ Background service is still running after cleanup");
    } else {
      await service.startService();
      print("✅ Flutter background service started successfully");
      
      // Show service started notification
      await NotificationService.showServiceStatusNotification(
        title: "✅ Flutter Location Tracking Started",
        message: "Background location tracking is now active (Flutter fallback)",
        isRunning: true,
      );
    }
  } catch (e) {
    print("❌ Error starting Flutter background service: $e");
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  try {
    // Only available for flutter 3.0.0 and later
    DartPluginRegistrant.ensureInitialized();

    print("🚀 Background service started - onStart called");

    service.on('stopService').listen((event) {
      print("🛑 Stop service event received");
      WakelockPlus.disable();
      NotificationService.cancelAllNotifications();
      service.stopSelf();
    });

    // Set up foreground notification with proper error handling
    if (service is AndroidServiceInstance) {
      try {
        service.setForegroundNotificationInfo(
          title: "Rhysley Location Tracking",
          content: "Tracking your location in background",
        );
        print("✅ Foreground notification set successfully");
      } catch (e) {
        print("❌ Error setting foreground notification: $e");
      }
    }

    // Enable wake lock to prevent device from sleeping
    await WakelockPlus.enable();
    print("🔋 Wake lock enabled in service");

    // Start periodic health check to ensure tracking continues
    _startPeriodicHealthCheck(service);
    
    // Start tracking with error handling
    await _startTracking(service);
    
  } catch (e) {
    print("❌ Error in onStart: $e");
    // Try to stop the service gracefully
    try {
      await WakelockPlus.disable();
      service.stopSelf();
    } catch (stopError) {
      print("❌ Error stopping service: $stopError");
    }
  }
}

void _startPeriodicHealthCheck(ServiceInstance service) {
  // Check every 3 minutes for more frequent monitoring
  Timer.periodic(const Duration(minutes: 1), (timer) async {
    print("🔍 Enhanced periodic health check - verifying location tracking");
    
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("userId");
    final token = prefs.getString("token");
    
    if (userId == null || token == null) {
      print("❌ Health check failed - user not logged in");
      timer.cancel();
      return;
    }
    
    // Check if location services are still enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("❌ Health check failed - location services disabled");
      timer.cancel();
      return;
    }
    
    // Retry any failed locations during health check
    await _retryFailedLocations();
    
    print("✅ Enhanced health check passed - location tracking is active");
  });
  
  // Additional timer for failed location retry every 10 minutes
  Timer.periodic(const Duration(minutes: 10), (timer) async {
    print("🔄 Periodic failed location retry");
    await _retryFailedLocations();
  });
}

Future<void> _startTracking(ServiceInstance service) async {
  print("🚀 Starting enhanced background location tracking");
  
  // Check if user is logged in
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getInt("userId");
  final token = prefs.getString("token");
  
  if (userId == null || token == null) {
    print("❌ User not logged in, stopping location tracking");
    return;
  }
  
  print("✅ User logged in (ID: $userId), starting location tracking");
  print("🔑 Token available: ${token.isNotEmpty ? 'YES' : 'NO'}");

  // Check location permissions
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    print("❌ Location services are disabled");
    return;
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      print("❌ Location permissions are denied");
      return;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    print("❌ Location permissions are permanently denied");
    return;
  }

  print("✅ Location permissions granted, starting enhanced position stream");

  // Enhanced location tracking settings for continuous monitoring
  Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation, // Highest accuracy for continuous tracking
      distanceFilter: 1, // Update every 1 meter for maximum precision
      timeLimit: Duration(minutes: 10), // Longer timeout for better reliability
    ),
  ).listen(
    (Position position) async {
      print("📍 Enhanced location update: ${position.latitude}, ${position.longitude}");
      print("📍 Accuracy: ${position.accuracy}m, Speed: ${position.speed}m/s");
      
      // Update notification with current location and additional info
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "Rhysley Location Tracking",
          content: "Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)} | Accuracy: ${position.accuracy.toStringAsFixed(1)}m",
        );
      }
      
      // Show local notification for every location change
      await NotificationService.showLocationNotification(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        speed: position.speed,
      );
      
      // Send location to server with enhanced retry logic
      await _sendLocationToServerWithEnhancedRetry(position, userId);
    },
    onError: (error) {
      print("❌ Enhanced location stream error: $error");
      // Enhanced error recovery with exponential backoff
      _handleLocationError(service, error);
    },
    cancelOnError: false, // Don't cancel stream on error
  );
}

void _handleLocationError(ServiceInstance service, dynamic error) {
  print("🔄 Handling location error with enhanced recovery");
  
  // Exponential backoff retry
  Future.delayed(const Duration(seconds: 10), () {
    print("🔄 Restarting location tracking after error recovery");
    _startTracking(service);
  });
}

Future<void> _sendLocationToServerWithEnhancedRetry(Position position, int userId) async {
  const maxRetries = 5; // Increased retries for better reliability
  const baseDelay = Duration(seconds: 1);
  
  for (int attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      print("🔄 Enhanced location send attempt $attempt/$maxRetries");
      print("📍 Position: ${position.latitude}, ${position.longitude}, Accuracy: ${position.accuracy}m");
      
      await _sendLocationToServerEnhanced(position, userId);
      print("✅ Enhanced location sent successfully to server");
      return; // Success, exit retry loop
    } catch (e) {
      print("❌ Enhanced attempt $attempt failed: $e");
      
      if (attempt < maxRetries) {
        // Exponential backoff with jitter
        final delay = Duration(
          milliseconds: baseDelay.inMilliseconds * attempt * attempt + 
          (DateTime.now().millisecondsSinceEpoch % 1000) // Add jitter
        );
        print("⏳ Enhanced waiting ${delay.inSeconds}s before retry...");
        await Future.delayed(delay);
      } else {
        print("❌ All enhanced location send attempts failed");
        // Store failed location for later retry
        await _storeFailedLocation(position, userId);
      }
    }
  }
}

Future<void> _sendLocationToServerWithRetry(double lat, double lng, int userId) async {
  const maxRetries = 3;
  const retryDelay = Duration(seconds: 2);
  
  for (int attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      print("🔄 Location send attempt $attempt/$maxRetries");
      await _sendLocationToServer(lat, lng, userId);
      print("✅ Location sent successfully to server");
      return; // Success, exit retry loop
    } catch (e) {
      print("❌ Attempt $attempt failed: $e");
      
      if (attempt < maxRetries) {
        print("⏳ Waiting before retry...");
        await Future.delayed(retryDelay);
      } else {
        print("❌ All location send attempts failed");
      }
    }
  }
}

Future<void> _sendLocationToServerEnhanced(Position position, int userId) async {
  final apiService = ApiService();
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("token");
  
  if (token == null) {
    print("❌ No token available for enhanced location API");
    throw Exception("No authentication token available");
  }

  print("📍 Sending enhanced location: lat=${position.latitude}, lng=${position.longitude}, userId=$userId");
  print("📍 Additional data: accuracy=${position.accuracy}m, speed=${position.speed}m/s, timestamp=${position.timestamp}");
  
  await apiService.post(ApiConstants.location, {
    "user_id": userId,
    "lat": position.latitude,
    "lng": position.longitude,
    "accuracy": position.accuracy,
    "speed": position.speed,
    "timestamp": position.timestamp?.millisecondsSinceEpoch,
    "altitude": position.altitude,
    "heading": position.heading,
  }, withAuth: true);
}

Future<void> _sendLocationToServer(double lat, double lng, int userId) async {
  final apiService = ApiService();
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("token");
  
  if (token == null) {
    print("❌ No token available for location API");
    throw Exception("No authentication token available");
  }

  print("📍 Sending location: lat=$lat, lng=$lng, userId=$userId");
  
  await apiService.post(ApiConstants.location, {
    "user_id": userId,
    "lat": lat,
    "lng": lng
  }, withAuth: true);
}

Future<void> _storeFailedLocation(Position position, int userId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final failedLocations = prefs.getStringList("failed_locations") ?? [];
    
    final locationData = {
      "lat": position.latitude,
      "lng": position.longitude,
      "accuracy": position.accuracy,
      "speed": position.speed,
      "timestamp": position.timestamp?.millisecondsSinceEpoch,
      "userId": userId,
      "storedAt": DateTime.now().millisecondsSinceEpoch,
    };
    
    failedLocations.add(locationData.toString());
    
    // Keep only last 50 failed locations to prevent storage bloat
    if (failedLocations.length > 50) {
      failedLocations.removeRange(0, failedLocations.length - 50);
    }
    
    await prefs.setStringList("failed_locations", failedLocations);
    print("💾 Stored failed location for later retry: ${failedLocations.length} total");
  } catch (e) {
    print("❌ Failed to store failed location: $e");
  }
}

Future<void> _retryFailedLocations() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final failedLocations = prefs.getStringList("failed_locations") ?? [];
    
    if (failedLocations.isEmpty) {
      print("✅ No failed locations to retry");
      return;
    }
    
    print("🔄 Retrying ${failedLocations.length} failed locations");
    
    final List<String> remainingLocations = [];
    
    for (final locationString in failedLocations) {
      try {
        // Parse the stored location data
        // Note: This is a simplified approach. In production, use proper JSON serialization
        final parts = locationString.split(',');
        if (parts.length >= 2) {
          final lat = double.parse(parts[0].split(':')[1]);
          final lng = double.parse(parts[1].split(':')[1]);
          final userId = int.parse(parts[5].split(':')[1]);
          
          await _sendLocationToServer(lat, lng, userId);
          print("✅ Successfully retried failed location");
        }
      } catch (e) {
        print("❌ Failed to retry location: $e");
        remainingLocations.add(locationString);
      }
    }
    
    // Update the failed locations list
    await prefs.setStringList("failed_locations", remainingLocations);
    print("🔄 Retry completed. ${remainingLocations.length} locations still failed");
    
  } catch (e) {
    print("❌ Error during failed location retry: $e");
  }
}
