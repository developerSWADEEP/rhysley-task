import 'package:dio/dio.dart';
import '../../core/utils/storage_helper.dart';

class ApiService {
  final Dio _dio = Dio();

  ApiService() {
    _dio.options.headers["Content-Type"] = "application/json";
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  Future<Response> post(String url, Map<String, dynamic> data,
      {bool withAuth = false}) async {
    // Clear previous authorization header
    _dio.options.headers.remove("Authorization");
    
    if (withAuth) {
      final token = await StorageHelper.getToken();
      if (token != null && token.isNotEmpty) {
        _dio.options.headers["Authorization"] = "Bearer $token";
        print("🔐 Using Bearer Token: ${token.substring(0, 20)}...");
        print("🔐 Full Token Length: ${token.length}");
      } else {
        print("⚠️ No token available for authenticated request");
        throw Exception("No authentication token available");
      }
    }

    try {
      print("📤 Sending POST request to: $url");
      print("📤 Request data: $data");
      print("📤 Headers: ${_dio.options.headers}");
      
      final response = await _dio.post(url, data: data);
      print("📥 Response Status Code: ${response.statusCode}");

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        // ✅ Custom logs based on endpoint
        if (url.contains("login")) {
          print("✅ Login API Success ✅");
          print("Status Code: ${response.statusCode}");
          print("Response: ${response.data}");
        } else if (url.contains("location")) {
          print("📡 Location API Success 📡");
          print("Status Code: ${response.statusCode}");
          print("Response: ${response.data}");
        } else {
          print("✅ API Success: $url");
          print("Status Code: ${response.statusCode}");
          print("Response: ${response.data}");
        }
      }

      return response;
    } catch (e) {
      print("❌ Error in POST request ($url): $e");
      if (e is DioException) {
        print("❌ Dio Error Type: ${e.type}");
        print("❌ Dio Error Message: ${e.message}");
        print("❌ Dio Response: ${e.response?.data}");
        print("❌ Dio Status Code: ${e.response?.statusCode}");
        
        // Check if it's an authentication error
        if (e.response?.statusCode == 401 || e.response?.statusCode == 500) {
          print("🔐 Authentication error detected - token might be invalid");
          // Clear the token if it's invalid
          await StorageHelper.clearToken();
        }
      }
      rethrow;
    }
  }
}
