# Rhysley - Location Tracking App Documentation

## Overview

**Rhysley** is a Flutter-based location tracking application designed for continuous background location monitoring. The app provides real-time location tracking with server integration, native Android service implementation, and comprehensive notification system.

## Features

### 🎯 Core Features

- **Real-time Location Tracking**: Continuous GPS location monitoring with high precision
- **Background Service**: Native Android service for uninterrupted tracking when app is closed
- **Server Integration**: Automatic location data transmission to remote API
- **User Authentication**: Secure login system with employee ID and password
- **Notification System**: Real-time notifications for location updates and service status
- **Cross-platform Support**: Android and iOS compatibility

### 📱 User Interface Features

- **Modern Material Design**: Clean, intuitive interface with gradient themes
- **Real-time Status Display**: Live location coordinates, accuracy, and speed information
- **Service Control**: Start/stop tracking with visual feedback
- **API Status Monitoring**: Real-time feedback on server communication
- **Animated Transitions**: Smooth UI animations and transitions

### 🔧 Technical Features

- **Dual Service Architecture**: Native Android service + Flutter background service
- **Wake Lock Management**: Prevents device sleep during tracking
- **Enhanced Error Handling**: Exponential backoff retry mechanism
- **Permission Management**: Comprehensive location and notification permissions
- **Offline Storage**: Failed location data storage for retry
- **Health Monitoring**: Periodic service health checks

## Architecture

### 📁 Project Structure

```
lib/
├── core/
│   ├── constants/          # API endpoints and app constants
│   └── utils/              # Utility functions and helpers
├── data/
│   ├── models/             # Data models (LoginResponse, etc.)
│   └── services/           # Core services
│       ├── api_service.dart
│       ├── auth_service.dart
│       ├── background_location.dart
│       ├── location_service.dart
│       ├── native_location_service.dart
│       └── notification_service.dart
├── presentation/
│   ├── screens/            # UI screens
│   │   ├── login_screen.dart
│   │   └── home_screen.dart
│   └── widgets/            # Reusable UI components
├── providers/              # State management
│   ├── auth_provider.dart
│   └── location_provider.dart
└── main.dart               # App entry point
```

### 🏗️ Architecture Components

#### 1. **Service Layer**
- **ApiService**: HTTP client with Dio for server communication
- **AuthService**: User authentication and token management
- **BackgroundLocationService**: Flutter background service implementation
- **NativeLocationService**: Native Android service integration
- **NotificationService**: Local notification management

#### 2. **State Management**
- **AuthProvider**: Manages user authentication state
- **LocationProvider**: Handles location tracking state and API calls

#### 3. **Presentation Layer**
- **LoginScreen**: User authentication interface
- **HomeScreen**: Main tracking interface with controls and status

#### 4. **Native Integration**
- **Android**: Native Kotlin service for continuous background tracking
- **iOS**: Flutter background service with iOS-specific configurations

## Implementation Details

### 🔐 Authentication System

The app uses a secure authentication system with the following flow:

1. **Login Process**:
   ```dart
   // User enters employee ID and password
   final success = await auth.login(emailCtrl.text.trim(), passCtrl.text);
   ```

2. **Token Management**:
   - JWT tokens stored securely using SharedPreferences
   - Automatic token validation for API requests
   - Token refresh handling for expired sessions

3. **API Integration**:
   - Base URL: `https://api.helixtahr.com/api/v1`
   - Login endpoint: `/login`
   - Location endpoint: `/location`

### 📍 Location Tracking Implementation

#### Dual Service Architecture

1. **Native Android Service** (Primary):
   ```kotlin
   class NativeLocationService : Service(), LocationListener {
       // Continuous location tracking
       // Foreground service with persistent notification
       // Wake lock management
       // Server communication
   }
   ```

2. **Flutter Background Service** (Fallback):
   ```dart
   FlutterBackgroundService().configure(
     androidConfiguration: AndroidConfiguration(
       onStart: onStart,
       isForegroundMode: true,
       foregroundServiceTypes: [AndroidForegroundType.location],
     ),
   );
   ```

#### Location Settings

- **Accuracy**: `LocationAccuracy.bestForNavigation` (highest precision)
- **Distance Filter**: 1 meter (updates every meter of movement)
- **Time Limit**: 10 minutes timeout for reliability
- **Providers**: GPS + Network location providers

### 🔔 Notification System

#### Notification Types

1. **Location Notifications**:
   - Real-time location updates
   - Detailed coordinates, accuracy, and speed
   - Big text style with rich content

2. **Service Status Notifications**:
   - Service start/stop events
   - Error notifications
   - Health status updates

#### Implementation

```dart
await NotificationService.showLocationNotification(
  latitude: position.latitude,
  longitude: position.longitude,
  accuracy: position.accuracy,
  speed: position.speed,
);
```

### 🔄 Error Handling & Retry Logic

#### Enhanced Retry Mechanism

1. **Exponential Backoff**:
   ```dart
   const maxRetries = 5;
   final delay = Duration(milliseconds: baseDelay.inMilliseconds * attempt * attempt);
   ```

2. **Failed Location Storage**:
   - Stores failed locations locally
   - Retries during periodic health checks
   - Maintains last 50 failed locations

3. **Health Monitoring**:
   - Periodic health checks every minute
   - Service status validation
   - Automatic service restart on failure

### 🛡️ Permission Management

#### Required Permissions

1. **Location Permissions**:
   - `ACCESS_FINE_LOCATION`
   - `ACCESS_COARSE_LOCATION`
   - `ACCESS_BACKGROUND_LOCATION`

2. **Notification Permissions**:
   - `POST_NOTIFICATIONS`

3. **System Permissions**:
   - `WAKE_LOCK` (prevents device sleep)
   - `FOREGROUND_SERVICE` (background operation)

#### Permission Flow

```dart
// Request location when in use first
var status = await Permission.locationWhenInUse.request();

// Then request background location
if (status.isGranted) {
  var backgroundStatus = await Permission.locationAlways.request();
}
```

## Usage Guide

### 🚀 Getting Started

1. **Installation**:
   ```bash
   flutter pub get
   flutter run
   ```

2. **Permissions**:
   - Grant location permissions (when in use + always)
   - Grant notification permissions
   - Allow background app refresh

3. **Login**:
   - Enter employee ID and password
   - App will authenticate and store session

4. **Start Tracking**:
   - Tap "Start Tracking" button
   - Service will initialize and begin location monitoring

### 📱 User Interface

#### Login Screen
- **Employee ID Field**: Enter your employee identifier
- **Password Field**: Enter your password
- **Sign In Button**: Authenticate and proceed to main screen

#### Home Screen
- **Status Card**: Shows current tracking status
- **Location Card**: Displays real-time location coordinates
- **API Status Card**: Shows server communication status
- **Control Buttons**: Start/stop tracking controls
- **Info Card**: Background tracking information

### 🔧 Configuration

#### API Configuration
```dart
class ApiConstants {
  static const baseUrl = "https://api.helixtahr.com/api/v1";
  static const login = "$baseUrl/login";
  static const location = "$baseUrl/location";
}
```

#### Location Settings
```dart
const LocationSettings(
  accuracy: LocationAccuracy.bestForNavigation,
  distanceFilter: 1, // Update every 1 meter
  timeLimit: Duration(minutes: 10),
)
```

## Technical Specifications

### 📦 Dependencies

```yaml
dependencies:
  flutter: sdk: flutter
  cupertino_icons: ^1.0.8
  dio: ^5.7.0                    # HTTP client
  shared_preferences: ^2.3.2     # Local storage
  provider: ^6.1.2              # State management
  geolocator: ^13.0.1            # Location services
  flutter_background_service: ^5.0.5  # Background service
  permission_handler: ^11.3.1   # Permission management
  flutter_local_notifications: ^17.2.2  # Notifications
  wakelock_plus: ^1.2.8         # Wake lock management
```

### 🎯 Platform Support

- **Android**: Full background service support
- **iOS**: Limited background support (iOS restrictions)
- **Minimum SDK**: Android API 21+ (Android 5.0)
- **Flutter Version**: 3.9.0+

### 🔋 Battery Optimization

- **Wake Lock**: Prevents device sleep during tracking
- **Efficient Location Updates**: 1-meter distance filter
- **Background Service**: Optimized for minimal battery impact
- **Health Monitoring**: Prevents unnecessary service restarts

## Troubleshooting

### Common Issues

1. **Location Not Updating**:
   - Check location permissions
   - Verify location services are enabled
   - Check device battery optimization settings

2. **Background Service Stopping**:
   - Disable battery optimization for the app
   - Check Android Doze mode settings
   - Verify wake lock permissions

3. **Notifications Not Showing**:
   - Grant notification permissions
   - Check notification channel settings
   - Verify app notification settings

4. **API Connection Issues**:
   - Check internet connectivity
   - Verify API endpoint configuration
   - Check authentication token validity

### Debug Information

The app provides comprehensive logging for debugging:

```dart
print("🚀 Starting location tracking service");
print("📍 Location update: ${position.latitude}, ${position.longitude}");
print("✅ Location sent successfully to server");
print("❌ Error: $error");
```

## Development Notes

### 🔧 Development Setup

1. **Prerequisites**:
   - Flutter SDK 3.9.0+
   - Android Studio / VS Code
   - Physical device for testing (background services)

2. **Build Configuration**:
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --release
   ```

3. **Testing**:
   - Test on physical device for accurate background behavior
   - Monitor device logs for service status
   - Test various app states (foreground, background, killed)

### 📝 Code Style

- **Dart**: Follows Flutter/Dart style guidelines
- **Architecture**: Clean architecture with separation of concerns
- **State Management**: Provider pattern for state management
- **Error Handling**: Comprehensive error handling with logging

### 🔄 Future Enhancements

- **iOS Background Service**: Enhanced iOS background support
- **Offline Mode**: Enhanced offline location storage
- **Map Integration**: Visual map display of tracked locations
- **Analytics**: Location tracking analytics and insights
- **Multi-user Support**: Support for multiple user accounts

## Support

For technical support or questions about the implementation:

1. Check the troubleshooting section above
2. Review the debug logs for error information
3. Test on different devices and Android versions
4. Monitor battery usage and optimize settings

---

**Version**: 1.0.0  
**Last Updated**: 2024  
**Platform**: Flutter (Android/iOS)
