import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/staff_provider.dart';

class ViewAttendanceStaff extends StatefulWidget {
  const ViewAttendanceStaff({super.key});

  @override
  State<ViewAttendanceStaff> createState() => _ViewAttendanceStaffState();
}

class _ViewAttendanceStaffState extends State<ViewAttendanceStaff> {

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        context.read<StaffProvider>().loadTodayClassAttendance());
  }

  @override
  Widget build(BuildContext context) {
    final staff = context.watch<StaffProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('📋 View Attendance'),
        centerTitle: true,
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),

      body: staff.loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(staff),
    );
  }

  Widget _buildBody(StaffProvider staff) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.deepPurple.shade50,
            Colors.white,
            Colors.blueGrey.shade50,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: staff.isFreeHour
            ? _buildFreeHourUI()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildClassHeader(staff),
                  const SizedBox(height: 24),
                  _buildAnimatedTitle(),
                  const SizedBox(height: 16),
                  _buildAttendanceStats(staff.students),
                  const SizedBox(height: 20),
                  Expanded(
                      child: _buildAnimatedStudentList(staff.students)),
                ],
              ),
      ),
    );
  }

  /// ---------- FREE HOUR ----------
  Widget _buildFreeHourUI() {
    return const Center(
      child: Text(
        "Free Hour — No class scheduled",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// ---------- CLASS HEADER ----------
  Widget _buildClassHeader(StaffProvider staff) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.school,
              color: Colors.deepPurple.shade800, size: 26),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(staff.className,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                Text(staff.subjectName,
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700)),
              ],
            ),
          ),
          Text("${staff.students.length} Students",
              style: TextStyle(
                  color: Colors.deepPurple.shade800,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  /// ---------- TITLE ----------
  Widget _buildAnimatedTitle() {
    return const Row(
      children: [
        Icon(Icons.people_alt_rounded),
        SizedBox(width: 10),
        Text("Student Attendance",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700)),
      ],
    );
  }

  /// ---------- STATS ----------
  Widget _buildAttendanceStats(List students) {
    final present =
        students.where((s) => s["status"] == "Present").length;
    final absent =
        students.where((s) => s["status"] == "Absent").length;
    final percent =
        students.isEmpty ? 0 : (present / students.length * 100).round();

    return Row(
      children: [
        Expanded(child: _stat("Present", "$present", Colors.green)),
        const SizedBox(width: 12),
        Expanded(child: _stat("Absent", "$absent", Colors.red)),
        const SizedBox(width: 12),
        Expanded(child: _stat("Percentage", "$percent%", Colors.blue)),
      ],
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(.3)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color)),
          Text(label),
        ],
      ),
    );
  }

  /// ---------- STUDENT LIST ----------
  Widget _buildAnimatedStudentList(List students) {
    return ListView.separated(
      itemCount: students.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final s = students[i];
        return _studentTile(s["roll"], s["name"], s["status"]);
      },
    );
  }

  Widget _studentTile(String roll, String name, String status) {
    Color color = status == "Present"
        ? Colors.green
        : status == "Absent"
            ? Colors.red
            : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.person, color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600)),
                Text("Roll: $roll",
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          Text(status,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }
}
