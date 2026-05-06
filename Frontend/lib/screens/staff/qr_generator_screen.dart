import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

class QrGeneratorScreen extends StatefulWidget {
  const QrGeneratorScreen({super.key});

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  String? _qrToken;
  bool _loading = false;
  int _secondsLeft = 0;
  Timer? _timer;

  String selectedClass = 'MAD-SEM4';
  int selectedPeriod = 1;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _generateQR() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get(
        '/attendance/generate-qr?classCode=$selectedClass&period=$selectedPeriod',
      );

      if (res['success'] == true) {
        setState(() {
          _qrToken = res['token'];
          _secondsLeft = res['expiresIn'] ?? 60;
          _loading = false;
        });
        _startTimer();
      } else {
        throw Exception(res['message'] ?? 'Failed to generate QR');
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        timer.cancel();
        setState(() => _qrToken = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('AUTH KEY GENERATOR', 
          style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13, color: const Color(0xFF0F172A))),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            _buildConfigurationPanel(),
            const SizedBox(height: 50),
            if (_loading)
              _buildLoadingState()
            else if (_qrToken != null)
              _buildQRDisplay()
            else
              _buildEmptyState(),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationPanel() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: const Color(0xFF1E293B).withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings_input_component_rounded, color: Color(0xFF4F46E5), size: 18),
              const SizedBox(width: 10),
              Text('SESSION PARAMETERS', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: const Color(0xFF0F172A), fontSize: 12, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 24),
          _buildDropdown<String>(
            label: 'Target Course',
            value: selectedClass,
            items: ['MAD-SEM4', 'DBS-SEM4', 'NSE-SEM4'],
            onChanged: (val) => setState(() => selectedClass = val!),
          ),
          const SizedBox(height: 20),
          _buildDropdown<int>(
            label: 'Academic Period',
            value: selectedPeriod,
            items: List.generate(8, (i) => i + 1),
            itemLabel: (i) => 'Period $i',
            onChanged: (val) => setState(() => selectedPeriod = val!),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    String Function(T)? itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
        const SizedBox(height: 10),
        DropdownButtonFormField<T>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          style: GoogleFonts.inter(color: const Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 14),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(itemLabel?.call(i) ?? i.toString()))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildQRDisplay() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(48),
            border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.1)),
            boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.1), blurRadius: 40, spreadRadius: 2)],
          ),
          child: QrImageView(
            data: _qrToken!,
            version: QrVersions.auto,
            size: 240.0,
            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF0F172A)),
            dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF4F46E5)),
          ),
        ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 48),
        _buildTimerIndicator(),
        const SizedBox(height: 32),
        TextButton.icon(
          onPressed: _generateQR,
          icon: const Icon(Icons.refresh_rounded, size: 20),
          label: const Text('REGENERATE SECURITY KEY'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF4F46E5), 
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 0.5, fontSize: 12),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildTimerIndicator() {
    final bool warning = _secondsLeft < 15;
    return Column(
      children: [
        Text(
          '$_secondsLeftS',
          style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w900, color: warning ? const Color(0xFFEF4444) : const Color(0xFF0F172A), letterSpacing: -1),
        ),
        const SizedBox(height: 4),
        Text('TIME TO EXPIRY', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: const Color(0xFF94A3B8))),
        const SizedBox(height: 24),
        Container(
          width: 220,
          height: 6,
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(seconds: 1),
                width: 220 * (_secondsLeft / 60),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: warning ? [const Color(0xFFEF4444), Colors.orange] : [const Color(0xFF4F46E5), const Color(0xFF818CF8)]),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate(target: warning ? 1 : 0).shimmer(color: Colors.red.withOpacity(0.1));
  }
  
  String get _secondsLeftS => _secondsLeft < 10 ? '0$_secondsLeft' : '$_secondsLeft';

  Widget _buildEmptyState() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), shape: BoxShape.circle),
          child: Icon(Icons.qr_code_2_rounded, size: 64, color: const Color(0xFFCBD5E1)),
        ),
        const SizedBox(height: 32),
        Text('Engine Inactive', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF475569))),
        const SizedBox(height: 8),
        const Text('Initialize the QR core to start student validation.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
        const SizedBox(height: 48),
        _buildActionBtn('START QR ENGINE', _generateQR),
      ],
    ).animate().fadeIn();
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        const CircularProgressIndicator(color: Color(0xFF4F46E5), strokeWidth: 3),
        const SizedBox(height: 24),
        Text('Generating Secure Token...', style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildActionBtn(String label, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 62,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        child: Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 14, letterSpacing: 1)),
      ),
    );
  }
}
