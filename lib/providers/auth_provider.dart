import 'package:flutter/material.dart';
import '../data/models/login_response.dart';
import '../data/services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  LoginResponse? loginResponse;
  bool isLoading = false;

  Future<bool> login(String email, String password) async {
    try {
      isLoading = true;
      notifyListeners();
      loginResponse = await _authService.login(email, password, 1.3565, 103.8090);
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
