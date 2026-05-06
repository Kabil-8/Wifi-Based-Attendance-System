import 'package:flutter/material.dart';

// Auth
import '../screens/auth/login_screen.dart';
import '../screens/auth/select_role_screen.dart';

// Student
import '../screens/student/student_dashboard.dart';
import '../screens/student/mark_attendance_screen.dart';
import '../screens/student/attendance_history_screen.dart';

// Staff
import '../screens/staff/staff_dashboard.dart';
import '../screens/staff/modify_attendance_screen.dart';
import '../screens/staff/class_location_screen.dart';

class Routes {
  static const login = '/';
  static const selectRole = '/select-role';

  static const studentDashboard = '/student-dashboard';
  static const markAttendance = '/mark-attendance';
  static const attendanceHistory = '/attendance-history';

  static const staffDashboard = '/staff-dashboard';
  static const modifyAttendance = '/modify-attendance';
  static const classLocation = '/class-location';

  static Map<String, WidgetBuilder> routes = {
    login: (_) => LoginScreen(),
    selectRole: (_) => SelectRoleScreen(),

    studentDashboard: (_) => StudentDashboard(),
    markAttendance: (_) => MarkAttendanceScreen(),
    attendanceHistory: (_) => AttendanceHistoryScreen(),

    staffDashboard: (_) => StaffDashboard(),
    modifyAttendance: (_) => ModifyAttendanceScreen(),
    classLocation: (_) => ClassLocationScreen(),
  };
}
