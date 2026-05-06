import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  String role = 'STUDENT';
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // ── Decorative Top Background ────────────────────────────────────
          Positioned(
            top: -50,
            left: -50,
            child: _buildCircle(250, const Color(0xFF4F46E5).withOpacity(0.05)),
          ).animate().fadeIn(duration: 1.seconds).scale(),

          Positioned(
            top: 100,
            right: -80,
            child: _buildCircle(300, const Color(0xFF818CF8).withOpacity(0.03)),
          ).animate().fadeIn(duration: 1.5.seconds).scale(),

          // ── Main Content ───────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // LOGO / ICON
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.12), blurRadius: 40, offset: const Offset(0, 15))
                        ],
                      ),
                      child: const Icon(
                        Icons.fingerprint_rounded,
                        size: 52,
                        color: Color(0xFF4F46E5),
                      ),
                    ).animate()
                     .fadeIn(duration: 800.ms)
                     .scale(delay: 200.ms),

                    const SizedBox(height: 32),

                    Text(
                      'Attendance Nexus',
                      style: GoogleFonts.inter(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

                    const SizedBox(height: 8),

                    Text(
                      'Universal Academic Identity Portal',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                        letterSpacing: 1,
                      ),
                    ).animate().fadeIn(delay: 600.ms),

                    const SizedBox(height: 54),

                    // CLEAN LIGHT FORM
                    Container(
                      padding: const EdgeInsets.all(36),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(36),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF1E293B).withOpacity(0.04), blurRadius: 40, offset: const Offset(0, 20))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildInputField(
                            controller: emailCtrl,
                            label: 'Email',
                            icon: Icons.alternate_email_rounded,
                          ).animate().fadeIn(delay: 800.ms).slideX(begin: -0.1),

                          const SizedBox(height: 24),

                          _buildInputField(
                            controller: passCtrl,
                            label: 'Password',
                            icon: Icons.lock_person_rounded,
                            isPassword: true,
                          ).animate().fadeIn(delay: 1.seconds).slideX(begin: 0.1),

                          const SizedBox(height: 24),

                          _buildRoleSelector()
                              .animate()
                              .fadeIn(delay: 1.2.seconds),

                          const SizedBox(height: 48),

                          _buildLoginButton(auth)
                              .animate()
                              .fadeIn(delay: 1.4.seconds)
                              .scale(begin: const Offset(0.95, 0.95)),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    Text(
                      'Developed for Modern Learning Institutions © 2026',
                      style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8), fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ).animate().fadeIn(delay: 2.seconds),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF94A3B8), letterSpacing: 1.5)),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          obscureText: isPassword && _obscureText,
          style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontWeight: FontWeight.w600, fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: const Color(0xFF94A3B8),
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscureText = !_obscureText),
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: role,
          style: GoogleFonts.inter(color: const Color(0xFF334155), fontSize: 14, fontWeight: FontWeight.bold),
          icon: const Icon(Icons.unfold_more_rounded, color: Color(0xFF94A3B8), size: 20),
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'STUDENT', child: Text('Student')),
            DropdownMenuItem(value: 'STAFF', child: Text('Staff')),
          ],
          onChanged: (val) => setState(() => role = val!),
        ),
      ),
    );
  }

  Widget _buildLoginButton(AuthProvider auth) {
    return Container(
      height: 62,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Dark Navy
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: auth.isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: Center(
          child: auth.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 3, color: Colors.white),
                )
              : Text(
                  'Login',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    // Basic validation before hitting the server
    if (emailCtrl.text.trim().isEmpty || passCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter your email and password', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(24),
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok = await auth.login(
      emailCtrl.text.trim(),
      passCtrl.text.trim(),
      role,
    );

    if (!mounted) return;

    if (ok && auth.user != null) {
      // ✅ Navigate using ACTUAL role from server — not the UI dropdown
      final serverRole = auth.user!.role.toUpperCase();
      final route = serverRole == 'STUDENT' ? '/student-dashboard' : '/staff-dashboard';
      Navigator.pushReplacementNamed(context, route);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auth.errorMessage ?? 'Authentication failed',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(24),
        ),
      );
    }
  }
}