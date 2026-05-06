import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:attendance_app_frontend/config/api_config.dart';

class ViewAttendanceScreen extends StatefulWidget {
  const ViewAttendanceScreen({super.key});

  @override
  State<ViewAttendanceScreen> createState() => _ViewAttendanceScreenState();
}

class _ViewAttendanceScreenState extends State<ViewAttendanceScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? attendanceData;
  bool isLoading = true;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchAttendance();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<String> getToken() async {
    // Replace with your token retrieval method
    return 'YOUR_JWT_TOKEN';
  }

  Future<void> fetchAttendance() async {
    setState(() => isLoading = true);
    final token = await getToken();
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/student/dashboard'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            attendanceData = data['data'];
            isLoading = false;
          });
          _animationController.forward();
        }
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch attendance')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  double _percentage(int attended, int total) {
    return total == 0 ? 0 : (attended / total) * 100;
  }

  Color _statusColor(double percent) {
    if (percent >= 75) return Colors.green;
    if (percent >= 60) return Colors.orange;
    return Colors.red;
  }

  String _statusText(double percent) {
    if (percent >= 75) return "Good";
    if (percent >= 60) return "Warning";
    return "Low Attendance";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Attendance Details")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : attendanceData == null
              ? const Center(child: Text("No attendance data"))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      elevation: 3,
                      child: ListTile(
                        title: const Text("Today's Attendance"),
                        subtitle: Text(
                          attendanceData!['today']['marked']
                              ? attendanceData!['today']['status']
                              : 'NOT MARKED',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        leading: Icon(
                          attendanceData!['today']['status'] == 'PRESENT'
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: attendanceData!['today']['status'] ==
                                  'PRESENT'
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Overall Attendance',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Text(
                                'Total Days: ${attendanceData!['stats']['total']}'),
                            Text(
                                'Present: ${attendanceData!['stats']['present']}'),
                            Text(
                                'Percentage: ${attendanceData!['stats']['percentage']}%'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
