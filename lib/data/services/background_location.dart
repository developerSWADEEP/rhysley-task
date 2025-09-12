import 'dart:ui';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'location_service.dart';
import 'api_service.dart';
import '../../core/constants/api_constants.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      autoStartOnBoot: true,
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  service.startService();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // bring to foreground
  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: "Rhysley Location Tracking",
      content: "Tracking your location in background",
    );
  }

  // Start periodic health check to ensure tracking continues
  _startPeriodicHealthCheck(service);
  
  _startTracking(service);
}

void _startPeriodicHealthCheck(ServiceInstance service) {
  // Check every 5 minutes if location tracking is still active
  Timer.periodic(const Duration(minutes: 5), (timer) async {
    print("🔍 Periodic health check - verifying location tracking");
    
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
    
    print("✅ Health check passed - location tracking is active");
  });
}

void _startTracking(ServiceInstance service) async {
  print("🚀 Starting background location tracking");
  
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

  print("✅ Location permissions granted, starting position stream");

  // Start location tracking with improved settings
  Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Update every 5 meters for better tracking
      timeLimit: Duration(minutes: 2), // Increased timeout
    ),
  ).listen(
    (Position position) async {
      print("📍 Location update: ${position.latitude}, ${position.longitude}");
      
      // Update notification with current location
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "Rhysley Location Tracking",
          content: "Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}",
        );
      }
      
      // Send location to server with retry logic
      await _sendLocationToServerWithRetry(position.latitude, position.longitude, userId);
    },
    onError: (error) {
      print("❌ Location stream error: $error");
      // Restart tracking after error
      Future.delayed(const Duration(seconds: 5), () {
        print("🔄 Restarting location tracking after error");
        _startTracking(service);
      });
    },
    cancelOnError: false, // Don't cancel stream on error
  );
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
