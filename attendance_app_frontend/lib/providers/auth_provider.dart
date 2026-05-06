import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';


class AuthProvider extends ChangeNotifier {
  bool isLoading = false;
  UserModel? user;
  String? token;
  String? errorMessage;

  Future<bool> login(String email, String password, String role) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      print("📤 Sending login request");

      final res = await ApiService.post(
        "/auth/login",
        body: {
          "email": email,
          "password": password,
          "role": role,
        },
      );

      print("📥 Login response: $res");

      if (res["success"] != true) {
        errorMessage = res["message"] ?? "Login failed";
        isLoading = false;
        notifyListeners();
        return false;
      }

      final userJson = res["user"];
      final tokenJson = res["token"];

      if (userJson == null || tokenJson == null) {
        errorMessage = "Invalid server response";
        isLoading = false;
        notifyListeners();
        return false;
      }

      user = UserModel(
        id: userJson["_id"] ?? "",
        name: userJson["name"] ?? "",
        role: userJson["role"] ?? "",
      );

      token = tokenJson;

      // ✅ correct place
      AuthService.setToken(token!);

      isLoading = false;
      notifyListeners();
      return true;

    } catch (e) {
      errorMessage = "Login error";
      isLoading = false;
      notifyListeners();
      print("❌ Login error: $e");
      return false;
    }
  }

  void logout() {
    user = null;
    token = null;
    AuthService.clearToken(); // ✅ correct
    notifyListeners();
  }

  bool get isLoggedIn => user != null;
}
