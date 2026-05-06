import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/staff_provider.dart';
import '../auth/login_screen.dart';

class StaffProfileScreen extends StatelessWidget {
  const StaffProfileScreen({super.key});

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
    final staff = context.watch<StaffProvider>();
    final name = staff.staffName.isNotEmpty ? staff.staffName : (auth.user?.name ?? 'Admin');
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('STAFF PROFILE', 
          style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13, color: const Color(0xFF0F172A))),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF312E81), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(name, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(staff.department.isNotEmpty ? staff.department : 'STAFF', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF4F46E5))),
            ),
            const SizedBox(height: 48),
            
            // Stats summary
            Row(
              children: [
                _buildStatBox('Classes', staff.stats["classes"].toString(), Icons.class_outlined),
                const SizedBox(width: 16),
                _buildStatBox('Students', staff.stats["students"].toString(), Icons.people_outline),
                const SizedBox(width: 16),
                _buildStatBox('Sessions Today', staff.stats["today"].toString(), Icons.event_available),
              ],
            ),

            const SizedBox(height: 48),

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

  Widget _buildStatBox(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF64748B)),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
            Text(label, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
