import '../models/login_response.dart';
import 'api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/storage_helper.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  Future<LoginResponse> login(
      String email, String password, double lat, double lng) async {
    final response = await _apiService.post(ApiConstants.login, {
      "email": email,
      "password": password,
      "lng": lng,
      "lat": lat,
      "browser_id": DateTime.now().millisecondsSinceEpoch
    });

    final loginData = LoginResponse.fromJson(response.data);
    await StorageHelper.saveToken(loginData.token);
    await StorageHelper.saveUserId(loginData.userId);

    return loginData;
  }
}
