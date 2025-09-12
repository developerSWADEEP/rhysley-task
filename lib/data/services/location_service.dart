import 'api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/storage_helper.dart';

class LocationService {
  final ApiService _apiService = ApiService();

  Future<bool> sendLocation(double lat, double lng) async {
    try {
      final userId = await StorageHelper.getUserId();
      if (userId == null) {
        print("❌ No user ID found, cannot send location");
        return false;
      }

      print("📍 Sending location: lat=$lat, lng=$lng, userId=$userId");
      
      await _apiService.post(ApiConstants.location, {
        "user_id": userId,
        "lat": lat,
        "lng": lng
      }, withAuth: true);
      
      print("✅ Location sent successfully");
      return true;
    } catch (e) {
      print("❌ Failed to send location: $e");
      return false;
    }
  }

  Future<bool> sendLocationWithRetry(double lat, double lng, {int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      print("🔄 Location send attempt $attempt/$maxRetries");
      
      final success = await sendLocation(lat, lng);
      if (success) {
        return true;
      }
      
      if (attempt < maxRetries) {
        print("⏳ Waiting before retry...");
        await Future.delayed(Duration(seconds: attempt * 2)); // Exponential backoff
      }
    }
    
    print("❌ All location send attempts failed");
    return false;
  }
}
