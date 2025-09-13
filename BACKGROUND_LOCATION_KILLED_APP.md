# Background Location Tracking - App Killed Scenario

This document explains how the Rhysley app continues to track location even when the app is killed by the user on iOS.

## Overview

The app now implements iOS-specific background location tracking using **Significant Location Change Monitoring**, which allows location updates to continue even when the app is completely terminated by the user.

## Key Components

### 1. iOS Background Capabilities (`Info.plist`)

```xml
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
    <string>background-processing</string>
    <string>background-fetch</string>
</array>
```

### 2. Location Permissions

- **NSLocationAlwaysAndWhenInUseUsageDescription**: Required for continuous location tracking
- **NSLocationWhenInUseUsageDescription**: For foreground location access
- **NSLocationAlwaysUsageDescription**: For background location access

### 3. Background Location Service (`BackgroundLocationService.swift`)

The native iOS service implements:

- **Significant Location Change Monitoring**: Uses `startMonitoringSignificantLocationChanges()` which works even when app is killed
- **Standard Location Updates**: For more frequent updates when app is active
- **Background Task Management**: Handles iOS background execution limits
- **Event Streaming**: Sends location updates to Flutter via EventChannel

### 4. Flutter Integration

- **NativeLocationService**: Handles communication with iOS native service
- **Background Location Stream**: Listens to location updates from killed app scenarios
- **Enhanced Server Communication**: Sends location data with additional metadata

## How It Works

### When App is Active
1. Standard location updates provide frequent, accurate positioning
2. Location data is sent to server in real-time
3. UI updates with current location information

### When App is Backgrounded
1. Significant location change monitoring continues
2. Location updates are sent when user moves significantly (typically 100+ meters)
3. Background app refresh may trigger additional updates

### When App is Killed by User
1. **iOS automatically restarts the app** when significant location changes occur
2. The app runs briefly in background to process the location update
3. Location data is sent to server
4. App may terminate again after processing

## Important iOS Behaviors

### App Lifecycle
- When killed, iOS keeps the location monitoring active at the system level
- When significant location change occurs, iOS launches the app briefly
- App has ~30 seconds to process the location update
- App terminates again after processing

### Location Accuracy
- Significant location changes typically trigger at 100+ meter movements
- Less frequent than active/background mode updates
- Still provides meaningful location tracking for most use cases

### Battery Optimization
- iOS automatically manages battery usage
- Significant location changes are more battery-efficient than continuous tracking
- System may throttle updates based on user behavior patterns

## Implementation Details

### Swift Service Features
```swift
// Significant location change monitoring (works when killed)
locationManager.startMonitoringSignificantLocationChanges()

// Standard updates (when app is active)
locationManager.startUpdatingLocation()

// Background location updates enabled
locationManager.allowsBackgroundLocationUpdates = true
```

### Flutter Integration
```dart
// Listen to background location updates
NativeLocationService.backgroundLocationStream.listen((data) {
  // Process location from killed app scenario
  _sendBackgroundLocationToServer(
    data['latitude'], 
    data['longitude'], 
    data['accuracy'],
    data['isSignificantChange'],
    data['source']
  );
});
```

## Testing the Feature

### Manual Testing
1. Start location tracking in the app
2. Force kill the app from app switcher
3. Move to a different location (100+ meters away)
4. Check server logs for location updates
5. Check device logs for app launch events

### Verification Points
- [ ] App requests "Always" location permission
- [ ] Location tracking continues after app kill
- [ ] Significant location changes trigger app restart
- [ ] Location data is sent to server
- [ ] Notifications show location updates

## Limitations and Considerations

### iOS System Limits
- App may not restart immediately after kill
- Location updates depend on iOS system behavior
- Battery optimization may affect update frequency
- User can disable background app refresh

### User Privacy
- Requires "Always" location permission
- Users may deny this permission
- Clear explanation of why continuous tracking is needed

### Server Considerations
- Location updates may arrive in batches
- Implement proper handling of delayed updates
- Consider implementing location validation
- Handle potential duplicate or stale data

## Troubleshooting

### Common Issues
1. **Permission Denied**: User must grant "Always" location permission
2. **No Updates**: Check if background app refresh is enabled
3. **Delayed Updates**: iOS may throttle updates based on usage patterns
4. **App Not Restarting**: Verify significant location change threshold

### Debug Steps
1. Check iOS Settings > Privacy & Security > Location Services
2. Verify app has "Always" permission
3. Check iOS Settings > General > Background App Refresh
4. Monitor device logs for app launch events
5. Test with significant location changes (100+ meters)

## Future Enhancements

### Potential Improvements
- Implement geofencing for more precise triggers
- Add location accuracy validation
- Implement smart batching of location updates
- Add user preferences for update frequency
- Implement location history and analytics

### Advanced Features
- Push notifications for location-based events
- Integration with other background services
- Enhanced battery optimization
- Location-based automation triggers

## Conclusion

The implementation provides robust background location tracking that continues even when the app is killed by the user. While it relies on iOS system behavior and has some limitations, it provides a reliable solution for continuous location monitoring in most scenarios.

The key to success is proper permission handling, clear user communication about why continuous location access is needed, and robust server-side handling of potentially delayed or batched location updates.
