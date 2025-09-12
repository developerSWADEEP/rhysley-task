# Location Tracking Fixes and Implementation

## Issues Fixed

### 1. **500 Error in Location API** ✅
**Problem**: The login response was returning the token in `reset_password_token` field, but the code was looking for `token` field.

**Solution**: Updated `LoginResponse.fromJson()` to correctly extract the token from the nested data object:
```dart
final data = json["data"] ?? {};
final token = data["reset_password_token"] ?? "";
final userId = data["id"] ?? 0;
```

### 2. **Missing Bearer Token Authentication** ✅
**Problem**: Location API calls were not properly authenticated with Bearer token.

**Solution**: Enhanced `ApiService` to:
- Clear previous authorization headers before each request
- Properly set Bearer token for authenticated requests
- Add detailed logging for debugging
- Handle authentication errors gracefully

### 3. **Background Location Tracking Issues** ✅
**Problem**: Background service wasn't handling authentication and permissions properly.

**Solution**: Completely rewrote `background_location.dart` to:
- Check if user is logged in before starting tracking
- Verify location permissions before starting
- Handle authentication in background service
- Add proper error handling and logging
- Show persistent notification with location updates
- Support both Android and iOS background modes

### 4. **Enhanced Location Service** ✅
**Problem**: Basic location service without retry logic or proper error handling.

**Solution**: Enhanced `LocationService` to:
- Return success/failure status
- Add retry mechanism with exponential backoff
- Better error handling and logging
- Validate user ID before sending location

## Key Features Implemented

### 🔐 **Authentication**
- Proper Bearer token extraction from login response
- Token validation before API calls
- Secure token storage using SharedPreferences

### 📍 **Location Tracking**
- High accuracy GPS tracking
- 10-meter distance filter for efficient updates
- Background location tracking with persistent notification
- Automatic permission handling

### 🔄 **Error Handling & Retry Logic**
- Retry mechanism for failed API calls
- Exponential backoff for retries
- Comprehensive error logging
- User-friendly error messages

### 📱 **User Interface**
- Real-time location display
- API status indicators
- Start/Stop tracking controls
- Permission status handling
- Background tracking information

## Files Modified

1. **`lib/data/models/login_response.dart`** - Fixed token extraction
2. **`lib/data/services/api_service.dart`** - Enhanced authentication and error handling
3. **`lib/data/services/location_service.dart`** - Added retry logic and better error handling
4. **`lib/data/services/background_location.dart`** - Complete rewrite for background tracking
5. **`lib/providers/location_provider.dart`** - Added tracking status and retry methods
6. **`lib/presentation/screens/home_screen.dart`** - Enhanced UI with controls and status
7. **`lib/main.dart`** - Improved permission handling

## Testing Instructions

### 1. **Login Test**
```bash
# Run the app and login with:
Email: NAV1003
Password: Pp@1234567
```
- Verify successful login
- Check logs for "✅ Login API Success ✅"
- Verify token is saved correctly

### 2. **Foreground Location Tracking**
- After login, you'll see the Home screen
- Location tracking should start automatically
- Verify location updates in the UI
- Check API status shows "Location sent successfully"

### 3. **Background Location Tracking**
- Minimize the app or turn off screen
- Check for persistent notification "Rhysley Location Tracking"
- Verify location continues to update in background
- Check logs for background location updates

### 4. **API Testing**
Monitor logs for:
```
📤 Sending POST request to: https://api.helixtahr.com/api/v1/location
🔐 Using Bearer Token: eyJpdiI6InBvT2RvQ1JFbGN6...
📤 Request data: {user_id: 2035, lat: 1.3565952, lng: 103.809024}
📡 Location API Success 📡
Status Code: 200
```

## Permissions Required

### Android (Already configured in AndroidManifest.xml)
- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`
- `ACCESS_BACKGROUND_LOCATION`
- `FOREGROUND_SERVICE`
- `FOREGROUND_SERVICE_LOCATION`

### iOS (Configure in Info.plist)
Add these keys to `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to track your position.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs location access to track your position even when the app is in the background.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>This app needs location access to track your position even when the app is in the background.</string>
```

## Troubleshooting

### Common Issues

1. **500 Error Still Occurring**
   - Check if token is properly extracted from login response
   - Verify Bearer token format in API calls
   - Check server logs for authentication issues

2. **Background Tracking Not Working**
   - Ensure background location permission is granted
   - Check if notification is showing
   - Verify service is running in background

3. **Location Not Updating**
   - Check GPS is enabled on device
   - Verify location permissions are granted
   - Test in different locations (indoor vs outdoor)

### Debug Commands
```bash
# Check logs
flutter logs

# Run in debug mode
flutter run --debug

# Check permissions
adb shell dumpsys package com.example.rhysley | grep permission
```

## API Endpoints

### Login API
```
POST https://api.helixtahr.com/api/v1/login
Content-Type: application/json

{
  "email": "NAV1003",
  "password": "Pp@1234567",
  "lng": 103.809024,
  "lat": 1.3565952,
  "browser_id": 3417089516
}
```

### Location API
```
POST https://api.helixtahr.com/api/v1/location
Content-Type: application/json
Authorization: Bearer <token>

{
  "user_id": 2035,
  "lat": 1.3565952,
  "lng": 103.809024
}
```

## Next Steps

1. **Test the implementation** with the provided credentials
2. **Verify background tracking** works when app is minimized
3. **Check API responses** in logs
4. **Test on different devices** (Android/iOS)
5. **Monitor battery usage** for optimization

The implementation now provides robust geo-fencing/geo-tracking functionality that works both in foreground and background modes with proper authentication and error handling.
