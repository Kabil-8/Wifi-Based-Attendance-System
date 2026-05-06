import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../services/api_service.dart';

class StudentProvider extends ChangeNotifier {
  List<AttendanceModel> attendanceList = [];
  bool isLoading = false;

  Future<void> loadAttendance(String studentId) async {
    try {
      isLoading = true;
      notifyListeners();

      final res = await ApiService.get("/student/$studentId/attendance");

      attendanceList = (res["attendance"] as List)
          .map((e) => AttendanceModel(
                date: e["date"],
                present: e["present"],
              ))
          .toList();

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      notifyListeners();
      print("Attendance load error: $e");
    }
  }
}
