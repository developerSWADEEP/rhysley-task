import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:rhysley/providers/location_provider.dart';
import 'presentation/screens/login_screen.dart';
import 'data/services/background_location.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request location permission before starting service
  await _requestLocationPermission();

  await initializeService(); // background location service
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> _requestLocationPermission() async {
  print("🔐 Requesting location permissions...");
  
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
