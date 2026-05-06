import 'package:flutter/material.dart';
import '../services/api_service.dart';

class StaffProvider extends ChangeNotifier {
  /// -------- EXISTING --------
  List<Map<String, dynamic>> students = [];
  bool loading = false;

  /// -------- VIEW SCREEN --------
  String className = "";
  String subjectName = "";
  bool isFreeHour = false;

  /// -------- DASHBOARD FIELDS --------
  String staffName = "";
  String department = "";
  Map<String, dynamic> stats = {
    "classes": 0,
    "students": 0,
    "today": 0,
  };

  /// -------- CLASSES --------
  List<Map<String, dynamic>> classes = [];

  /// -------- SUBJECTS for selected class --------
  List<Map<String, dynamic>> subjects = [];

  // ================================
  // Load students by class (existing)
  // ================================
  Future<void> loadStudents(String classId) async {
    try {
      loading = true;
      notifyListeners();

      final res = await ApiService.get("/class/$classId/students");
      students = List<Map<String, dynamic>>.from(res["students"]);
    } catch (e) {
      print("Load students error: $e");
    }

    loading = false;
    notifyListeners();
  }

  // ================================
  // Save attendance (existing)
  // ================================
  Future<void> saveAttendance(List<Map<String, dynamic>> data) async {
    try {
      await ApiService.post(
        "/attendance/bulk-update",
        body: {"records": data},
      );
    } catch (e) {
      print("Save attendance error: $e");
    }
  }

  // ================================
  // Load today class attendance (existing)
  // ================================
  Future<void> loadTodayClassAttendance() async {
    try {
      loading = true;
      notifyListeners();

      final res = await ApiService.get("/attendance/today-class");

      className = res["className"] ?? "";
      subjectName = res["subjectName"] ?? "";
      isFreeHour = res["isFreeHour"] ?? false;
      students = List<Map<String, dynamic>>.from(res["students"] ?? []);
    } catch (e) {
      print("Today attendance load error: $e");
    }

    loading = false;
    notifyListeners();
  }

  // ================================
  // Load dashboard info
  // ================================
  Future<void> loadDashboard() async {
    try {
      loading = true;
      notifyListeners();

      final res = await ApiService.get("/staff/dashboard");

      staffName = res["staffName"] ?? "";
      department = res["department"] ?? "";
      stats = Map<String, dynamic>.from(res["stats"] ?? {});
    } catch (e) {
      print("Dashboard load error: $e");
    }

    loading = false;
    notifyListeners();
  }

  // ================================
  // Load staff classes from backend
  // ================================
  Future<void> loadClasses() async {
    try {
      loading = true;
      notifyListeners();

      final res = await ApiService.get("/staff/classes");
      classes = List<Map<String, dynamic>>.from(res["classes"] ?? []);
    } catch (e) {
      print("Load classes error: $e");
      classes = [];
    }

    loading = false;
    notifyListeners();
  }

  // ================================
  // Load subjects for a class
  // ================================
  Future<void> loadSubjects(String classId) async {
    try {
      loading = true;
      notifyListeners();

      final res = await ApiService.get("/staff/class/$classId/subjects");
      subjects = List<Map<String, dynamic>>.from(res["subjects"] ?? []);
    } catch (e) {
      print("Load subjects error: $e");
      subjects = [];
    }

    loading = false;
    notifyListeners();
  }

  // ================================
  // Add subject to a class
  // ================================
  Future<String?> addSubject(
    String classId,
    String code,
    String name, {
    Map<String, dynamic>? schedule,
  }) async {
    try {
      final res = await ApiService.post(
        "/staff/class/$classId/subject",
        body: {"code": code, "name": name, "schedule": schedule ?? {}},
      );
      subjects = List<Map<String, dynamic>>.from(res["subjects"] ?? []);
      notifyListeners();
      return null; // success
    } catch (e) {
      print("Add subject error: $e");
      return e.toString();
    }
  }

  // ================================
  // Delete subject from a class
  // ================================
  Future<String?> deleteSubject(String classId, String subjectCode) async {
    try {
      final res = await ApiService.delete(
        "/staff/class/$classId/subject/$subjectCode",
      );
      subjects = List<Map<String, dynamic>>.from(res["subjects"] ?? []);
      notifyListeners();
      return null; // success
    } catch (e) {
      print("Delete subject error: $e");
      return e.toString();
    }
  }

  // ================================
  // Update WiFi SSID for a class
  // ================================
  Future<String?> updateClassWifi(
    String classId,
    String wifiSSID,
    String room,
  ) async {
    try {
      await ApiService.put(
        "/staff/class/$classId/wifi",
        body: {"wifiSSID": wifiSSID, "room": room},
      );
      // Refresh classes list
      await loadClasses();
      return null; // success
    } catch (e) {
      print("Update WiFi error: $e");
      return e.toString();
    }
  }

  // ================================
  // UPDATE STUDENT STATUS (existing)
  // ================================
  Future<bool> updateStudentStatus(String studentId, String status) async {
    try {
      final res = await ApiService.post("/attendance/update-status", body: {
        "studentId": studentId,
        "status": status,
      });

      if (res["success"]) {
        await loadTodayClassAttendance();
        return true;
      }
    } catch (e) {
      print("Update status error: $e");
    }
    return false;
  }
}
