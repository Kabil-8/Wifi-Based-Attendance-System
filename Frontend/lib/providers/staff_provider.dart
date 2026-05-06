import 'package:flutter/material.dart';
import '../services/api_service.dart';

class StaffProvider extends ChangeNotifier {
  /// -------- EXISTING --------
  List<Map<String, dynamic>> students = [];
  bool loading = false;

  /// -------- NEW FOR VIEW SCREEN --------
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

  /// ================================
  /// Load students by class (existing)
  /// ================================
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

  /// ================================
  /// Save attendance (existing)
  /// ================================
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

  /// ================================
  /// Load today class attendance (existing)
  /// ================================
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

  /// ================================
  /// NEW — Load dashboard info
  /// ================================
  Future<void> loadDashboard() async {
    try {
      loading = true;
      notifyListeners();

      final res = await ApiService.get("/staff/dashboard");

      /*
      Expected backend response:
      {
        "staffName": "John Doe",
        "department": "Computer Science",
        "stats": {
          "classes": 5,
          "students": 120,
          "today": 3
        }
      }
      */

      staffName = res["staffName"] ?? "";
      department = res["department"] ?? "";
      stats = Map<String, dynamic>.from(res["stats"] ?? {});

    } catch (e) {
      print("Dashboard load error: $e");
    }

    loading = false;
    notifyListeners();
  }
}
