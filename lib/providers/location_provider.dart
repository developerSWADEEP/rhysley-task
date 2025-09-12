import 'package:flutter/material.dart';
import '../data/services/location_service.dart';

class LocationProvider with ChangeNotifier {
  final LocationService _locationService = LocationService();
  bool _isTracking = false;
  String _lastLocationStatus = "Not started";

  bool get isTracking => _isTracking;
  String get lastLocationStatus => _lastLocationStatus;

  Future<void> updateLocation(double lat, double lng) async {
    _lastLocationStatus = "Sending location...";
    notifyListeners();
    
    final success = await _locationService.sendLocation(lat, lng);
    _lastLocationStatus = success ? "Location sent successfully" : "Failed to send location";
    notifyListeners();
  }

  Future<void> updateLocationWithRetry(double lat, double lng) async {
    _lastLocationStatus = "Sending location with retry...";
    notifyListeners();
    
    final success = await _locationService.sendLocationWithRetry(lat, lng);
    _lastLocationStatus = success ? "Location sent successfully" : "All retry attempts failed";
    notifyListeners();
  }

  void setTrackingStatus(bool isTracking) {
    _isTracking = isTracking;
    notifyListeners();
  }
}
