import '../services/api_service.dart';

class AuthService {
  static String? _token;

  /// =========================
  /// Store token
  /// =========================
  static void setToken(String token) {
    _token = token;
    print("🔐 Token stored");
  }

  /// =========================
  /// Get token
  /// =========================
  static String? getToken() {
    return _token;
  }

  /// =========================
  /// Authorization header helper
  /// =========================
  static Map<String, String> authHeader() {
    if (_token == null) return {};
    return {
      "Authorization": "Bearer $_token",
    };
  }

  /// =========================
  /// Clear token (logout)
  /// =========================
  static void clearToken() {
    _token = null;
    print("🚪 Token cleared");
  }

  /// =========================
  /// Optional login wrapper (can keep or remove)
  /// =========================
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
    String role,
  ) async {
    print("📡 AuthService.login called");

    final res = await ApiService.post(
      "/auth/login",
      body: {
        "email": email,
        "password": password,
        "role": role,
      },
    );

    print("📨 AuthService response: $res");

    if (res["success"] == true && res["token"] != null) {
      setToken(res["token"]);
    }

    return res;
  }
}
