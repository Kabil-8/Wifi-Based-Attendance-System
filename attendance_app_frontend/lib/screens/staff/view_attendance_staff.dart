import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
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
    Future.microtask(() => context.read<StaffProvider>().loadTodayClassAttendance());
  }

  @override
  Widget build(BuildContext context) {
    final staff = context.watch<StaffProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('ATTENDANCE LOG', 
          style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 13, color: const Color(0xFF0F172A))),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFF1F5F9)),
        ),
      ),
      body: staff.loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
          : _buildBody(staff),
    );
  }

  Widget _buildBody(StaffProvider staff) {
    if (staff.isFreeHour) return _buildFreeHourUI();

    return Column(
      children: [
        _buildClassHeader(staff),
        _buildAttendanceStats(staff.students),
        Expanded(
          child: _buildStudentList(staff.students),
        ),
      ],
    );
  }

  Widget _buildFreeHourUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), shape: BoxShape.circle),
            child: Icon(Icons.event_busy_rounded, size: 48, color: const Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 24),
          Text('No Session Scheduled', 
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF334155))),
          const SizedBox(height: 8),
          const Text('Currently in a non-scheduled academic period.', 
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildClassHeader(StaffProvider staff) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Dark Slate for contrast in header
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(staff.className, style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  Text(staff.subjectName, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _headerInfo('Total Registry', staff.students.length.toString()),
              _headerInfo('Session Code', 'ID-104'),
              _headerInfo('Status', 'Active'),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _headerInfo(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
        const SizedBox(height: 4),
        Text(val, style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildAttendanceStats(List students) {
    final present = students.where((s) => s["status"].toString().toLowerCase() == "present").length;
    final absent = students.where((s) => s["status"].toString().toLowerCase() == "absent").length;
    final od = students.where((s) => s["status"].toString().toLowerCase() == "od").length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _statBox('Present', present.toString(), const Color(0xFF10B981)),
          const SizedBox(width: 12),
          _statBox('Absent', absent.toString(), const Color(0xFFEF4343)),
          const SizedBox(width: 12),
          _statBox('On-Duty', od.toString(), const Color(0xFF3B82F6)),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _statBox(String label, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(20), 
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: const Color(0xFF1E293B).withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]
        ),
        child: Column(
          children: [
            Text(val, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 2),
            Text(label.toUpperCase(), style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w900, color: const Color(0xFF94A3B8), letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentList(List students) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final s = students[index];
        return _buildStudentTile(s).animate(delay: (400 + (index * 40)).ms).fadeIn().slideY(begin: 0.05);
      },
    );
  }

  Widget _buildStudentTile(dynamic student) {
    final status = student["status"] as String;
    final id = student["id"] as String;
    final color = status.toLowerCase() == "present" 
        ? const Color(0xFF10B981) 
        : status.toLowerCase() == "absent" 
            ? const Color(0xFFEF4444) 
            : const Color(0xFF3B82F6);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(24), 
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: const Color(0xFF1E293B).withOpacity(0.02), blurRadius: 10)]
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showStatusPicker(context, id, student["name"], status),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(Icons.person_rounded, color: color, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(student["name"], style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF1E293B))),
                      Text('Reg: ${student["roll"]}', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text(status.toUpperCase(), style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showStatusPicker(BuildContext context, String studentId, String name, String currentStatus) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(35))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Protocol Update', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF3B82F6), fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Text(name, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
            const SizedBox(height: 32),
            _statusOption(context, studentId, 'Present', const Color(0xFF10B981), Icons.check_circle_rounded),
            const SizedBox(height: 8),
            _statusOption(context, studentId, 'Absent', const Color(0xFFEF4444), Icons.cancel_rounded),
            const SizedBox(height: 8),
            _statusOption(context, studentId, 'OD', const Color(0xFF3B82F6), Icons.verified_user_rounded),
          ],
        ),
      ),
    );
  }

  Widget _statusOption(BuildContext context, String sid, String status, Color color, IconData icon) {
    return ListTile(
      onTap: () async {
        Navigator.pop(context);
        final success = await context.read<StaffProvider>().updateStudentStatus(sid, status);
        if (success && mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text('Identity Log updated to $status'),
               backgroundColor: const Color(0xFF0F172A),
               behavior: SnackBarBehavior.floating,
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
               margin: const EdgeInsets.all(20),
             )
           );
        }
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: const Color(0xFFF1F5F9))),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(status, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF334155))),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
    );
  }
}
