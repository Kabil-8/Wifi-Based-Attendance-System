import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/staff_provider.dart';

class ClassLocationScreen extends StatefulWidget {
  const ClassLocationScreen({super.key});

  @override
  State<ClassLocationScreen> createState() => _ClassLocationScreenState();
}

class _ClassLocationScreenState extends State<ClassLocationScreen> {
  Map<String, dynamic>? _selectedClass;
  final TextEditingController _roomController = TextEditingController();
  final TextEditingController _wifiController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffProvider>().loadClasses();
    });
  }

  @override
  void dispose() {
    _roomController.dispose();
    _wifiController.dispose();
    super.dispose();
  }

  void _onClassSelected(Map<String, dynamic>? cls) {
    if (cls == null) return;
    setState(() {
      _selectedClass = cls;
      final location = cls['location'] as Map<String, dynamic>? ?? {};
      _roomController.text = location['room']?.toString() ?? '';
      _wifiController.text = location['wifiRouter']?.toString() ?? '';
    });
  }

  Future<void> _saveLocation() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a class first'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _saving = true);

    final provider = context.read<StaffProvider>();
    final classId = _selectedClass!['_id']?.toString() ?? '';
    final error = await provider.updateClassWifi(
      classId,
      _wifiController.text.trim(),
      _roomController.text.trim(),
    );

    setState(() => _saving = false);

    if (!mounted) return;

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Saved! WiFi: ${_wifiController.text.trim()} · Room: ${_roomController.text.trim()}',
                  style: GoogleFonts.inter(fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final staff = context.watch<StaffProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'CLASS WIFI SETUP',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontSize: 13,
            color: const Color(0xFF0F172A),
          ),
        ),
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
          : staff.classes.isEmpty
              ? _buildEmptyState()
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                    children: [
                      _buildClassSelector(staff),
                      const SizedBox(height: 24),
                      _buildLocationCard(),
                      const SizedBox(height: 30),
                      _buildSaveButton(),
                      const SizedBox(height: 20),
                      _buildInfoBox(),
                    ],
                  ),
                ),
    );
  }

  // ---------- CLASS SELECTOR ----------
  Widget _buildClassSelector(StaffProvider staff) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.school_rounded, color: Color(0xFF4F46E5), size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                'Select Class',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<Map<String, dynamic>>(
            value: _selectedClass,
            hint: Text(
              'Choose a class…',
              style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14),
            ),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
            decoration: InputDecoration(
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
            style: GoogleFonts.inter(
              color: const Color(0xFF1E293B),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            items: staff.classes.map((cls) {
              return DropdownMenuItem<Map<String, dynamic>>(
                value: cls,
                child: Text(
                  '${cls['className'] ?? 'Class'} (${cls['classCode'] ?? ''})',
                ),
              );
            }).toList(),
            onChanged: _onClassSelected,
            validator: (v) => v == null ? 'Please select a class' : null,
          ),
          if (_selectedClass != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: Color(0xFF4F46E5)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dept: ${_selectedClass!['department'] ?? '—'} · Sem: ${_selectedClass!['semester'] ?? '—'}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF4F46E5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.08);
  }

  // ---------- LOCATION CARD ----------
  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.wifi_rounded, color: Color(0xFF10B981), size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                'Location & WiFi',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _roomController,
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
            decoration: InputDecoration(
              labelText: 'Room Number',
              labelStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
              prefixIcon: const Icon(Icons.door_front_door_rounded, color: Color(0xFF64748B), size: 20),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Enter room number' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _wifiController,
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
            decoration: InputDecoration(
              labelText: 'Wi-Fi SSID',
              labelStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
              prefixIcon: const Icon(Icons.wifi_rounded, color: Color(0xFF64748B), size: 20),
              helperText: 'Only students on this WiFi can be marked present',
              helperStyle: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Enter Wi-Fi SSID' : null,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.08);
  }

  // ---------- SAVE BUTTON ----------
  Widget _buildSaveButton() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _saving ? null : _saveLocation,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: _saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'SAVE CLASS LOCATION',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontSize: 13,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  // ---------- INFO BOX ----------
  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF10B981), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Students whose phone is connected to this Wi-Fi network during class hours will be automatically marked as present.',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF065F46), height: 1.5),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  // ---------- EMPTY STATE ----------
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.class_outlined, size: 52, color: Color(0xFF4F46E5)),
          ),
          const SizedBox(height: 24),
          Text(
            'No Classes Found',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You have no classes assigned yet.\nContact admin to assign classes.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
