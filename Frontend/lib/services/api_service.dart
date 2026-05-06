import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/auth_service.dart';

class ApiService {
  /// ==============================
  /// POST request
  /// ==============================
  static Future<dynamic> post(
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}$url"),
      headers: {
        "Content-Type": "application/json",
        ...AuthService.authHeader(),
        ...?headers,
      },
      body: jsonEncode(body ?? {}),
    );

    return _handleResponse(response);
  }

  /// ==============================
  /// GET request
  /// ==============================
  static Future<dynamic> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}$url"),
      headers: {
        ...AuthService.authHeader(),
        ...?headers,
      },
    );

    return _handleResponse(response);
  }

  /// ==============================
  /// Upload (multipart/form-data) request
  /// ==============================
  static Future<dynamic> upload(
    String url, { // 🔹 url is required
    File? file,
    String? token,
    Map<String, String>? fields,
  }) async {
    if (url.isEmpty) {
      throw Exception("ApiService.upload: url cannot be empty");
    }

    var request =
        http.MultipartRequest("POST", Uri.parse("${ApiConfig.baseUrl}$url"));

    // Add file if provided
    if (file != null) {
      request.files.add(
        await http.MultipartFile.fromPath("file", file.path),
      );
    }

    // Add extra form fields
    if (fields != null) {
      request.fields.addAll(fields);
    }

    // Add authorization header
    if (token != null) {
      request.headers["Authorization"] = "Bearer $token";
    }

    var response = await request.send();
    var respStr = await response.stream.bytesToString();

    return jsonDecode(respStr);
  }

  /// ==============================
  /// Response handler
  /// ==============================
  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          "API Error ${response.statusCode}: ${response.body}");
    }
  }
}
