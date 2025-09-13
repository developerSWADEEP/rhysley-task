import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:rhysley/providers/location_provider.dart';
import 'presentation/screens/login_screen.dart';
import 'data/services/background_location.dart';
import 'data/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service
  await NotificationService.initialize();

  // Request permissions before starting service
  await _requestPermissions();

  // Don't initialize service at startup to prevent crashes
  // Service will be initialized and started after login
  print("🚀 App starting without background service initialization");
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> _requestPermissions() async {
  print("🔐 Requesting all necessary permissions...");
  
  // Request notification permission
  var notificationStatus = await Permission.notification.status;
  if (notificationStatus.isDenied) {
    print("📱 Requesting notification permission...");
    notificationStatus = await Permission.notification.request();
  }
  
  if (notificationStatus.isGranted) {
    print("✅ Notification permission granted");
  } else {
    print("⚠️ Notification permission denied: $notificationStatus");
  }
  
  // Request location when in use permission first
  var status = await Permission.locationWhenInUse.status;
  if (status.isDenied) {
    print("📱 Requesting location when in use permission...");
    status = await Permission.locationWhenInUse.request();
  }

  if (status.isGranted) {
    print("✅ Location when in use permission granted");
    
    // Request background location permission
    print("🌙 Requesting background location permission...");
    var backgroundStatus = await Permission.locationAlways.status;
    if (backgroundStatus.isDenied) {
      backgroundStatus = await Permission.locationAlways.request();
    }
    
    if (backgroundStatus.isGranted) {
      print("✅ Background location permission granted");
    } else {
      print("⚠️ Background location permission denied: $backgroundStatus");
    }
  } else {
    print("❌ Location when in use permission denied: $status");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Geo Tracking App",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginScreen(),
    );
  }
}
