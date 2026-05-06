import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../auth/login_screen.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  void _logout(BuildContext context) {
    context.read<AuthProvider>().logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final student = context.watch<StudentProvider>();
    final name = auth.user?.name ?? 'Student';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';

    int present = student.stats["present"] ?? 0;
    int total = student.stats["total"] ?? 0;
    int absent = total - present;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('MY PROFILE', 
          style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13, color: const Color(0xFF0F172A))),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFdb2777), Color(0xFF9333ea)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [BoxShadow(color: const Color(0xFF9333ea).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(name, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
            Text('Roll: ${auth.user?.id ?? "N/A"}', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
            
            const SizedBox(height: 32),

            // Chart
            if (total > 0) ...[
              Container(
                height: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Stack(
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 60,
                        sections: [
                          PieChartSectionData(
                            color: const Color(0xFF10B981),
                            value: present.toDouble(),
                            title: '',
                            radius: 12,
                          ),
                          PieChartSectionData(
                            color: const Color(0xFFEF4444),
                            value: absent.toDouble(),
                            title: '',
                            radius: 12,
                          ),
                        ],
                      )
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${student.stats["percentage"] ?? 0}%', 
                            style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
                          Text('Attendance', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                label: Text('LOGOUT', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444), // Danger Red
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
