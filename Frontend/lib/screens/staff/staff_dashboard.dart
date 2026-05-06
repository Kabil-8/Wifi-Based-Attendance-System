import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/staff_provider.dart';

// Target screens
import 'view_attendance_staff.dart';
import 'modify_attendance_screen.dart';
import 'class_location_screen.dart';
import 'attendance_reports.dart';
import '../auth/login_screen.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideUpAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _headerSlideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0, .6)),
    );

    _slideUpAnimation = Tween(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(.2, .8)),
    );

    _scaleAnimation = Tween(begin: .95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(.4, 1)),
    );

    _headerSlideAnimation = Tween(
      begin: const Offset(-.5, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0, .4)),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffProvider>().loadDashboard(); // 🔥 backend call
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _logout(BuildContext context) {
    context.read<AuthProvider>().logout();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
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

  @override
  Widget build(BuildContext context) {
    final staff = context.watch<StaffProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: staff.loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(0, _slideUpAnimation.value),
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: child,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// ✅ HEADER — from backend
                      SlideTransition(
                        position: _headerSlideAnimation,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: Colors.indigo,
                              child: Text(
                                staff.staffName.isNotEmpty
                                    ? staff.staffName[0].toUpperCase()
                                    : "S",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Welcome back,",
                                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  Text(
                                    staff.staffName,
                                    style: const TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    staff.department,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      /// ✅ STATS — from backend
                      Row(
                        children: [
                          _stat("Classes", staff.stats["classes"].toString(), Icons.class_),
                          const SizedBox(width: 10),
                          _stat("Students", staff.stats["students"].toString(), Icons.people),
                          const SizedBox(width: 10),
                          _stat("Today", staff.stats["today"].toString(), Icons.today),
                        ],
                      ),

                      const SizedBox(height: 30),
                      const Text("Quick Actions",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 14),

                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        children: [
                          _action(context, Icons.visibility, "View Attendance",
                              const ViewAttendanceStaff()),
                          _action(context, Icons.edit_calendar, "Modify Attendance",
                              const ModifyAttendanceScreen()),
                          _action(context, Icons.location_on, "Class Location",
                              const ClassLocationScreen()),
                          _action(context, Icons.bar_chart, "Reports",
                              const AttendanceReports()),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _stat(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.indigo.shade50,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.indigo),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _action(BuildContext context, IconData icon, String title, Widget page) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _open(context, page),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.indigo.withOpacity(.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.indigo, size: 28),
            const Spacer(),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
