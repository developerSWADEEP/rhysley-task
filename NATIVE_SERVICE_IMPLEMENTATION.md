# Native Android Location Service Implementation

## Problem Solved

The Flutter background service was stopping after 5 minutes due to Android's background execution limits. This native Android service provides continuous location tracking that bypasses these limitations.

## Solution Overview

### ✅ **Native Android Service**
- **Continuous Tracking**: Runs independently of Flutter app lifecycle
- **Foreground Service**: Uses Android foreground service for persistent operation
- **Wake Lock**: Prevents device from sleeping during location tracking
- **START_STICKY**: Automatically restarts if killed by system

### ✅ **Key Features**
- **Real-time Location Updates**: Updates every 1 second or 1 meter movement
- **Dual Provider Support**: Uses both GPS and Network location providers
- **Native Notifications**: Shows location updates directly from native service
- **Server Integration**: Sends location data to your API endpoint
- **Flutter Integration**: Communicates with Flutter app via method channels

## Implementation Details

### 1. Native Service (`NativeLocationService.kt`)
```kotlin
class NativeLocationService : Service(), LocationListener {
    // Continuous location tracking
    // Foreground service with persistent notification
    // Wake lock management
    // Server communication
    // Flutter integration
}
```

### 2. Method Channel Communication
```kotlin
// MainActivity.kt
methodChannel.setMethodCallHandler { call, result ->
    when (call.method) {
        "startNativeLocationService" -> startService()
        "stopNativeLocationService" -> stopService()
        "isNativeServiceRunning" -> checkStatus()
    }
}
```

### 3. Flutter Integration
```dart
// native_location_service.dart
class NativeLocationService {
    static Future<bool> startService() async {
        return await _channel.invokeMethod('startNativeLocationService');
    }
    
    static Stream<Map<String, dynamic>> get locationStream {
        return _channel.receiveBroadcastStream();
    }
}
```

## Service Lifecycle Management

### **Service Startup**
1. **User Login**: Service starts after successful authentication
2. **Permission Check**: Validates location and notification permissions
3. **Foreground Service**: Starts as foreground service with persistent notification
4. **Wake Lock**: Acquires wake lock to prevent device sleeping
5. **Location Tracking**: Begins continuous location updates

### **Service Persistence**
- **START_STICKY**: Service restarts automatically if killed
- **Foreground Mode**: Runs as foreground service (not subject to background limits)
- **Wake Lock**: Prevents device from sleeping during tracking
- **Notification**: Persistent notification keeps service alive

### **Service Shutdown**
1. **User Logout**: Service stops when user logs out
2. **Manual Stop**: User can manually stop tracking
3. **Resource Cleanup**: Releases wake lock and stops location updates
4. **Notification Cleanup**: Cancels all notifications

## Location Tracking Configuration

### **Update Frequency**
```kotlin
private const val LOCATION_UPDATE_INTERVAL = 1000L // 1 second
private const val LOCATION_UPDATE_DISTANCE = 1f // 1 meter
```

### **Location Providers**
- **GPS Provider**: High accuracy outdoor tracking
- **Network Provider**: Indoor/urban area tracking
- **Best Available**: Uses most accurate provider available

### **Location Data**
```kotlin
val locationData = mapOf(
    "latitude" to location.latitude,
    "longitude" to location.longitude,
    "accuracy" to location.accuracy,
    "speed" to location.speed,
    "timestamp" to location.time,
    "altitude" to location.altitude,
    "bearing" to location.bearing
)
```

## Notification System

### **Foreground Notification**
- **Persistent**: Keeps service running in foreground
- **Location Info**: Shows current location coordinates
- **Service Status**: Indicates tracking is active

### **Location Update Notifications**
- **Real-time**: Shows every location change
- **Rich Content**: Detailed location information
- **Auto-dismiss**: Notifications auto-cancel after viewing

## Server Integration

### **API Communication**
```kotlin
val json = JSONObject().apply {
    put("user_id", userId)
    put("lat", location.latitude)
    put("lng", location.longitude)
    put("accuracy", location.accuracy)
    put("speed", location.speed)
    put("timestamp", location.time)
    put("altitude", location.altitude)
    put("heading", location.bearing)
}
```

### **Error Handling**
- **Retry Logic**: Automatic retry on network failures
- **Offline Storage**: Stores failed requests for later retry
- **Timeout Management**: 30-second timeouts for network requests

## Android Configuration

### **Manifest Permissions**
```xml
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

### **Service Declaration**
```xml
<service
    android:name=".NativeLocationService"
    android:exported="false"
    android:enabled="true"
    android:stopWithTask="false"
    android:foregroundServiceType="location" />
```

### **Dependencies**
```kotlin
implementation("com.squareup.okhttp3:okhttp:4.12.0")
implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
```

## Fallback Strategy

### **Primary**: Native Service
- **Best Performance**: Continuous tracking without Flutter limitations
- **System Integration**: Uses Android's native location services
- **Battery Optimized**: Efficient native implementation

### **Fallback**: Flutter Service
- **Backup Option**: If native service fails to start
- **Cross-platform**: Works on both Android and iOS
- **Flutter Integration**: Easier to maintain and debug

## Testing Instructions

### **1. Basic Functionality**
1. Install app and grant all permissions
2. Login to the app
3. Start location tracking
4. Verify native service starts successfully

### **2. Background Testing**
1. Start location tracking
2. Minimize app to background
3. Lock device screen
4. Verify location updates continue

### **3. Service Persistence**
1. Start location tracking
2. Force close the app
3. Verify service continues running
4. Check notifications for location updates

### **4. Long-term Testing**
1. Start location tracking
2. Leave device running for extended period
3. Verify service doesn't stop after 5 minutes
4. Check battery usage and performance

## Expected Behavior

### ✅ **Continuous Tracking**
- Location updates every 1 second or 1 meter
- Works when app is closed
- Works when screen is locked
- Continues running indefinitely

### ✅ **Notifications**
- Persistent foreground notification
- Location update notifications
- Service status notifications
- Rich content with location details

### ✅ **Server Communication**
- Sends location data to API
- Handles network failures gracefully
- Retries failed requests
- Stores offline data for later sync

### ✅ **Battery Management**
- Efficient wake lock usage
- Optimized location requests
- Proper resource cleanup
- Background execution limits respected

## Troubleshooting

### **Service Not Starting**
1. Check Android permissions
2. Verify user is logged in
3. Check device battery optimization settings
4. Review Android logs for errors

### **Location Updates Stopping**
1. Verify location services are enabled
2. Check GPS signal strength
3. Review notification permissions
4. Check device Doze mode settings

### **High Battery Usage**
1. Monitor wake lock usage
2. Check location update frequency
3. Review network request frequency
4. Optimize location accuracy settings

## Performance Considerations

### **Battery Usage**
- **Wake Lock**: Minimal usage, released when not needed
- **Location Updates**: Optimized frequency and accuracy
- **Network Requests**: Efficient HTTP client with timeouts
- **Notifications**: Minimal notification updates

### **Memory Usage**
- **Service Lifecycle**: Proper cleanup and resource management
- **Location Data**: Efficient data structures and serialization
- **Network Client**: Reused HTTP client instance
- **Coroutines**: Proper scope management and cancellation

This native service implementation provides robust, continuous location tracking that bypasses Android's background execution limitations while maintaining efficient resource usage and proper system integration.
