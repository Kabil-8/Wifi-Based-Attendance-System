import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  bool loading = true;
  List<dynamic> history = [];
  String error = "";

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    try {
      final res = await ApiService.get("/attendance/history");

      setState(() {
        history = res["records"]; // adjust if backend returns array directly
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Color statusColor(String status) {
    switch (status) {
      case "Present":
        return Colors.green;
      case "Absent":
        return Colors.red;
      case "OD":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData statusIcon(String status) {
    switch (status) {
      case "Present":
        return Icons.check_circle;
      case "Absent":
        return Icons.cancel;
      case "OD":
        return Icons.access_time;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance History"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(child: Text("Error: $error"))
              : history.isEmpty
                  ? const Center(child: Text("No attendance records found"))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final item = history[index];
                        final status = item["status"] ?? "Unknown";

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: Icon(
                              statusIcon(status),
                              color: statusColor(status),
                            ),
                            title: Text(
                              item["subject"] ?? "Subject",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              item["date"] ?? "",
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor(status).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: statusColor(status),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
