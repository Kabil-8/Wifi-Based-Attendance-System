import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../auth/login_screen.dart';

import 'qr_scan_request_screen.dart';
import 'attendance_history_screen.dart';
import 'student_profile_screen.dart';
import 'mark_attendance_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentProvider>().loadDashboard();
    });
  }

  final List<Widget> _pages = [
    const _StudentHomeTab(),
    const QrScanRequestScreen(),
    const AttendanceHistoryScreen(),
    const StudentProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final student = context.watch<StudentProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: student.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
          : IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: const Color(0xFF1E293B).withOpacity(0.04), blurRadius: 20, offset: const Offset(0, -5))
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (idx) => setState(() => _currentIndex = idx),
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF4F46E5),
            unselectedItemColor: const Color(0xFF94A3B8),
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900),
            unselectedLabelStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner_rounded), label: 'Scan QR'),
              BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'History'),
              BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// EX-HOME TAB CONTENT
// ---------------------------------------------------------
class _StudentHomeTab extends StatefulWidget {
  const _StudentHomeTab();
  @override
  State<_StudentHomeTab> createState() => _StudentHomeTabState();
}

class _StudentHomeTabState extends State<_StudentHomeTab> {
  int selectedSemester = 4;
  DateTime _focusedDay = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime? _selectedDay;
  
  List<dynamic> semesterAttendance = [];
  final Map<DateTime, List<dynamic>> _attendanceMap = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  void _handleLogout() {
    context.read<AuthProvider>().logout();
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  void _filterAndBuildMap(List<dynamic> allAttendance) {
    semesterAttendance = allAttendance.where((a) {
      final sem = a['semester']?.toString() ?? '1';
      return sem == selectedSemester.toString();
    }).toList();
    
    _attendanceMap.clear();
    for (var record in semesterAttendance) {
      if (record['date'] != null) {
        final parsed = DateTime.tryParse(record['date']);
        if (parsed != null) {
          final normalized = DateTime.utc(parsed.year, parsed.month, parsed.day);
          _attendanceMap.putIfAbsent(normalized, () => []).add(record);
        }
      }
    }
  }

  Map<String, int> _calculateSemesterStats() {
    int total = semesterAttendance.length;
    int present = semesterAttendance.where((a) => a['status'] == 'PRESENT' || a['status'] == 'LATE' || a['status'] == 'OD').length;
    int percentage = total > 0 ? ((present / total) * 100).round() : 0;
    return {'percentage': percentage};
  }

  @override
  Widget build(BuildContext context) {
    final student = context.watch<StudentProvider>();
    _filterAndBuildMap(student.allAttendance);
    
    final stats = _calculateSemesterStats();
    final name = student.dashboardData['user']?['name'] ?? 'Scholar';
    final overall = student.dashboardData['stats']?['percentage'] ?? student.stats['percentage'] ?? 0;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 100,
          backgroundColor: Colors.transparent,
          elevation: 0,
          pinned: false,
          floating: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF6366F1)], 
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
            ),
            collapseMode: CollapseMode.pin,
          ),
          leadingWidth: 70,
          leading: const Padding(
            padding: EdgeInsets.only(left: 20),
            child: CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(Icons.shield_rounded, color: Colors.white),
            ),
          ),
          title: Text('STUDENT DASHBOARD', 
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.9), fontSize: 12, letterSpacing: 1.5)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 15),
              child: IconButton(
                onPressed: _handleLogout,
                icon: const Icon(Icons.power_settings_new_rounded, color: Colors.white),
              ),
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome Back!', style: GoogleFonts.inter(color: Colors.black.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(name, 
                  style: GoogleFonts.inter(color: Colors.black, fontSize: 30, fontWeight: FontWeight.w900)),
                const SizedBox(height: 38),

                _buildStatGrid(stats, overall),

                const SizedBox(height: 40),

                _buildCalendarSection(),
                
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatGrid(Map<String, int> stats, dynamic overall) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [BoxShadow(color: const Color(0xFF1E293B).withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.speed_rounded, color: Color(0xFF4F46E5), size: 20),
                ),
                const SizedBox(height: 20),
                Text('$overall%', style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontSize: 24, fontWeight: FontWeight.w900)),
                Text('TOTAL LOAD', style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [BoxShadow(color: const Color(0xFF1E293B).withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.auto_graph_rounded, color: Color(0xFF8B5CF6), size: 20),
                ),
                const SizedBox(height: 20),
                Text('${stats['percentage']}%', style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontSize: 24, fontWeight: FontWeight.w900)),
                Text('CURR SEM', style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1);
  }

  Widget _buildCalendarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('ACTIVITY LOG', 
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A), letterSpacing: 1)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: selectedSemester,
                  items: [1,2,3,4,5,6,7,8].map((e) => DropdownMenuItem(value: e, child: Text('SEM $e', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)))).toList(),
                  onChanged: (val) => setState(() => selectedSemester = val!),
                  style: GoogleFonts.inter(color: const Color(0xFF4F46E5)),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF4F46E5), size: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [BoxShadow(color: const Color(0xFF1E293B).withOpacity(0.04), blurRadius: 40, offset: const Offset(0, 15))],
          ),
          child: Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2023, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (sDay, fDay) => setState(() { _selectedDay = sDay; _focusedDay = fDay; }),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  defaultTextStyle: GoogleFonts.inter(color: const Color(0xFF334155), fontWeight: FontWeight.w500),
                  weekendTextStyle: GoogleFonts.inter(color: Colors.redAccent),
                  todayDecoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.1), shape: BoxShape.circle),
                  selectedDecoration: const BoxDecoration(color: Color(0xFF4F46E5), shape: BoxShape.circle),
                  todayTextStyle: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 17, color: const Color(0xFF0F172A)),
                  leftChevronIcon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF64748B)),
                  rightChevronIcon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B)),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    final normalized = DateTime.utc(date.year, date.month, date.day);
                    final records = _attendanceMap[normalized];
                    if (records == null || records.isEmpty) return null;
                    final isPresent = records.every((r) => r['status'] != 'ABSENT');
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      width: 5, height: 5,
                      decoration: BoxDecoration(color: isPresent ? const Color(0xFF10B981) : const Color(0xFFEF4444), shape: BoxShape.circle),
                    );
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: Divider(height: 1, color: Color(0xFFF1F5F9)),
              ),
              _buildDayDetailList(),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
      ],
    );
  }

  Widget _buildDayDetailList() {
    if (_selectedDay == null) return const SizedBox.shrink();
    final normalized = DateTime.utc(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    final records = _attendanceMap[normalized] ?? [];
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: List.generate(8, (index) {
          final period = index + 1;
          final record = records.firstWhere((r) => r['period'] == period, orElse: () => null);
          
          Color bgColor = const Color(0xFFF1F5F9);
          if (record?['status'] == 'PRESENT') bgColor = const Color(0xFF10B981).withOpacity(0.08);
          if (record?['status'] == 'ABSENT') bgColor = const Color(0xFFEF4444).withOpacity(0.08);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text('$period', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 14, color: const Color(0xFF64748B)))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(record?['subject'] ?? 'Self Study Session', 
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF1E293B))),
                      Text(record?['time'] ?? 'No activity logged', style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 10)),
                    ],
                  ),
                ),
                _buildStatusIndicator(record?['status']),
              ],
            ),
          ).animate(delay: (index * 40).ms).fadeIn().slideX(begin: -0.05);
        }),
      ),
    );
  }

  Widget _buildStatusIndicator(String? status) {
    if (status == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
        child: Text('PENDING', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8))),
      );
    }
    
    Color color = status == 'ABSENT' ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    if (status == 'OD') color = const Color(0xFF3B82F6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(status, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
    );
  }
}