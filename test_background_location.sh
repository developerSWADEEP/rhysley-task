#!/bin/bash

# Background Location Tracking Test Script
# This script helps test the background location functionality

echo "🧪 Background Location Tracking Test Script"
echo "=========================================="

# Check if we're in the correct directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: Please run this script from the Flutter project root directory"
    exit 1
fi

echo "✅ Found Flutter project"

# Check iOS configuration
echo ""
echo "📱 Checking iOS Configuration..."

# Check Info.plist for background modes
if grep -q "UIBackgroundModes" ios/Runner/Info.plist; then
    echo "✅ Background modes configured in Info.plist"
else
    echo "❌ Background modes missing from Info.plist"
fi

# Check for location permissions
if grep -q "NSLocationAlwaysAndWhenInUseUsageDescription" ios/Runner/Info.plist; then
    echo "✅ Always location permission description found"
else
    echo "❌ Always location permission description missing"
fi

# Check for Swift files
if [ -f "ios/Runner/BackgroundLocationService.swift" ]; then
    echo "✅ BackgroundLocationService.swift found"
else
    echo "❌ BackgroundLocationService.swift missing"
fi

if [ -f "ios/Runner/AppDelegate.swift" ]; then
    echo "✅ AppDelegate.swift found"
    if grep -q "BackgroundLocationPlugin" ios/Runner/AppDelegate.swift; then
        echo "✅ BackgroundLocationPlugin registered in AppDelegate"
    else
        echo "❌ BackgroundLocationPlugin not registered in AppDelegate"
    fi
else
    echo "❌ AppDelegate.swift missing"
fi

# Check Flutter files
echo ""
echo "📱 Checking Flutter Implementation..."

if [ -f "lib/data/services/native_location_service.dart" ]; then
    echo "✅ NativeLocationService.dart found"
    if grep -q "backgroundLocationStream" lib/data/services/native_location_service.dart; then
        echo "✅ Background location stream implemented"
    else
        echo "❌ Background location stream missing"
    fi
else
    echo "❌ NativeLocationService.dart missing"
fi

if [ -f "lib/data/services/background_location.dart" ]; then
    echo "✅ BackgroundLocationService.dart found"
    if grep -q "_listenToBackgroundLocationUpdates" lib/data/services/background_location.dart; then
        echo "✅ Background location listener implemented"
    else
        echo "❌ Background location listener missing"
    fi
else
    echo "❌ BackgroundLocationService.dart missing"
fi

echo ""
echo "🧪 Testing Instructions:"
echo "========================"
echo ""
echo "1. Build and run the app on a physical iOS device"
echo "2. Grant 'Always' location permission when prompted"
echo "3. Start location tracking in the app"
echo "4. Force kill the app from the app switcher"
echo "5. Move to a different location (100+ meters away)"
echo "6. Check server logs for location updates"
echo "7. Check device logs for app restart events"
echo ""
echo "📋 Verification Checklist:"
echo "=========================="
echo "□ App requests 'Always' location permission"
echo "□ Location tracking continues after app kill"
echo "□ Significant location changes trigger app restart"
echo "□ Location data is sent to server"
echo "□ Notifications show location updates"
echo "□ Background app refresh is enabled in iOS settings"
echo ""
echo "🔍 Debug Commands:"
echo "=================="
echo "• Check iOS logs: xcrun simctl spawn booted log stream --predicate 'process == \"Runner\"'"
echo "• Check device logs: Console.app (on Mac) or Xcode Device window"
echo "• Monitor server: Check your API endpoint for location updates"
echo ""
echo "⚠️  Important Notes:"
echo "==================="
echo "• This feature only works on physical devices, not simulators"
echo "• Requires iOS 9.0 or later"
echo "• User must grant 'Always' location permission"
echo "• Background App Refresh must be enabled in iOS Settings"
echo "• Location updates depend on iOS system behavior"
echo ""
echo "✅ Test script completed!"
