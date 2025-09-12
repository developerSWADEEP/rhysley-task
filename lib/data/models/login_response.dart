class LoginResponse {
  final String token;
  final int userId;

  LoginResponse({required this.token, required this.userId});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    // Extract token from the data object, looking for access_token or token
    final data = json["data"] ?? {};
    final token = data["access_token"] ?? data["token"] ?? data["reset_password_token"] ?? "";
    final userId = data["id"] ?? 0;
    
    print("🔑 Extracted token: ${token.isNotEmpty ? token.substring(0, 20) + '...' : 'EMPTY'}");
    print("👤 Extracted userId: $userId");
    
    return LoginResponse(
      token: token,
      userId: userId,
    );
  }
}
