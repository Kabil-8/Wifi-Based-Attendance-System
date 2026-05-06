import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/staff_provider.dart';
import 'view_attendance_staff.dart';
import 'modify_attendance_screen.dart';
import 'class_location_screen.dart';
import 'attendance_reports.dart';
import 'qr_generator_screen.dart';
import 'manage_subjects_screen.dart';
import 'staff_profile_screen.dart';
import 'attendance_requests_screen.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffProvider>().loadDashboard();
    });
  }

  void _open(BuildContext context, Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: ScaleTransition(scale: anim, child: child)),
      ),
    );
  }

  final List<Widget> _pages = [
    const _StaffHomeTab(),
    const QrGeneratorScreen(),
    const AttendanceRequestsScreen(),
    const StaffProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final staff = context.watch<StaffProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: staff.loading
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
              BottomNavigationBarItem(icon: Icon(Icons.qr_code_2_rounded), label: 'QR Room'),
              BottomNavigationBarItem(icon: Icon(Icons.notification_important_rounded), label: 'Requests'),
              BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaffHomeTab extends StatelessWidget {
  const _StaffHomeTab();

  void _open(BuildContext context, Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: ScaleTransition(scale: anim, child: child)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final staff = context.watch<StaffProvider>();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 100,
          backgroundColor: Colors.transparent,
          elevation: 0,
          pinned: false,
          floating: true,
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF312E81), Color(0xFF4338CA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
            ),
          ),
          leadingWidth: 70,
          leading: Padding(
            padding: const EdgeInsets.only(left: 20, top: 8, bottom: 8),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 2),
              ),
              child: CircleAvatar(
                backgroundColor: Colors.white12,
                child: Text(
                  staff.staffName.isNotEmpty ? staff.staffName[0].toUpperCase() : "S",
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('System Admin', 
                style: GoogleFonts.inter(color: Colors.white.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w500)),
              Text(staff.staffName,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsRow(staff),
                const SizedBox(height: 40),
                Text(
                  'Staff Dashboard',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                    letterSpacing: 0.5,
                  ),
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 24),
                _buildActionGrid(context),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(StaffProvider staff) {
    return Row(
      children: [
        _buildStatItem('Courses', staff.stats["classes"].toString(), Icons.layers_rounded, const Color(0xFF4F46E5)),
        const SizedBox(width: 14),
        _buildStatItem('Students', staff.stats["students"].toString(), Icons.group_rounded, const Color(0xFF7C3AED)),
        const SizedBox(width: 14),
        _buildStatItem('Sessions', staff.stats["today"].toString(), Icons.verified_rounded, const Color(0xFF10B981)),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildStatItem(String label, String val, IconData icon, Color accentColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(color: const Color(0xFF1E293B).withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: accentColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: accentColor, size: 18),
            ),
            const SizedBox(height: 14),
            Text(val, style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontSize: 20, fontWeight: FontWeight.w900)),
            Text(label, style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    final actions = [
      {'title': 'View Log', 'subtitle': 'Daily tracking', 'icon': Icons.list_alt_rounded, 'page': const ViewAttendanceStaff()},
      {'title': 'Modify', 'subtitle': 'Manual override', 'icon': Icons.tune_rounded, 'page': const ModifyAttendanceScreen()},
      {'title': 'WiFi Setup', 'subtitle': 'Assign WiFi SSID', 'icon': Icons.wifi_rounded, 'page': const ClassLocationScreen()},
      {'title': 'Subjects', 'subtitle': 'Add & manage', 'icon': Icons.book_rounded, 'page': const ManageSubjectsScreen()},
      {'title': 'Reports', 'subtitle': 'Audits & exports', 'icon': Icons.assessment_rounded, 'page': const AttendanceReports()},
      {'title': 'QR Generator', 'subtitle': 'QR generator', 'icon': Icons.qr_code_scanner_rounded, 'page': const QrGeneratorScreen()},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final item = actions[index];
        return _buildActionCard(
          context,
          item['title'] as String,
          item['subtitle'] as String,
          item['icon'] as IconData,
          item['page'] as Widget,
        ).animate(delay: (400 + (index * 80)).ms).fadeIn().slideY(begin: 0.1);
      },
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String subtitle, IconData icon, Widget page) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1E293B).withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _open(context, page),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFF334155), size: 22),
                ),
                const Spacer(),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
