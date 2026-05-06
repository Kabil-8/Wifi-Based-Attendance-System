import 'package:flutter/material.dart';
import '../services/api_service.dart';

class StudentProvider extends ChangeNotifier {
  Map<String, dynamic> dashboardData = {};
  List<dynamic> allAttendance = [];
  Map<String, dynamic> stats = {
    "total": 0,
    "present": 0,
    "absent": 0,
    "percentage": 0,
  };
  bool isLoading = false;

  Future<void> loadDashboard() async {
    try {
      isLoading = true;
      notifyListeners();

      final dashRes = await ApiService.get("/student/dashboard");
      final histRes = await ApiService.get("/attendance/history");

      if (dashRes["success"] == true && histRes["success"] == true) {
        dashboardData = dashRes["data"] ?? {};
        allAttendance = histRes["data"] ?? [];
        _calculateStats();
      }
    } catch (e) {
      print("Dashboard load error: $e");
    }

    isLoading = false;
    notifyListeners();
  }

  void _calculateStats() {
    int total = allAttendance.length;
    int present = allAttendance.where((a) => a['status'] == 'PRESENT' || a['status'] == 'LATE' || a['status'] == 'OD').length;
    int absent = allAttendance.where((a) => a['status'] == 'ABSENT').length;
    int percentage = total > 0 ? ((present / total) * 100).round() : 0;
    
    stats = {
      'total': total,
      'present': present,
      'absent': absent,
      'percentage': percentage,
    };
  }
}
