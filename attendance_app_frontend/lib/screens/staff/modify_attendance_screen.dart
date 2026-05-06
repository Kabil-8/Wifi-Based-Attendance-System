import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/staff_provider.dart';

class ModifyAttendanceScreen extends StatefulWidget {
  const ModifyAttendanceScreen({super.key});

  @override
  State<ModifyAttendanceScreen> createState() => _ModifyAttendanceScreenState();
}

class _ModifyAttendanceScreenState extends State<ModifyAttendanceScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _selectedClass;
  Map<String, dynamic>? _selectedSubject;
  final List<String> _statusOptions = ['Present', 'Absent', 'OD'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffProvider>().loadClasses();
    });
  }

  void _onClassSelected(Map<String, dynamic>? cls) {
    if (cls == null) return;
    setState(() {
      _selectedClass = cls;
      _selectedSubject = null;
    });
    context.read<StaffProvider>().loadStudents(cls['_id'].toString());
  }

  String get _displayClassName => _selectedClass != null
      ? '${_selectedClass!['className'] ?? ''} (${_selectedClass!['classCode'] ?? ''})'
      : 'No class selected';

  String get _displaySubjectName => _selectedSubject?['name']?.toString() ?? 'All Subjects';

  List<Map<String, dynamic>> get _subjects =>
      List<Map<String, dynamic>>.from(_selectedClass?['subjects'] ?? []);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StaffProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'BATCH ADJUSTMENT',
          style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13, color: const Color(0xFF0F172A)),
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
      body: provider.loading && provider.classes.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
          : Column(
              children: [
                _buildSelectors(provider),
                if (_selectedClass != null)
                  provider.loading
                      ? const Expanded(child: Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5))))
                      : provider.students.isEmpty
                          ? _buildNoStudents()
                          : Expanded(child: _buildStudentList(provider)),
                if (_selectedClass != null && provider.students.isNotEmpty)
                  _buildActionFooter(provider),
              ],
            ),
    );
  }

  Widget _buildSelectors(StaffProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        children: [
          // Class selector
          _buildHeader(provider),
          const SizedBox(height: 16),
          if (provider.classes.isEmpty && !provider.loading)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFDBA74)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFF97316), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No classes assigned. Ask admin to assign a class.',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(StaffProvider provider) {
    final presentCount = provider.students
        .where((s) => (s['status'] ?? '').toString().toLowerCase() == 'present')
        .length;

    return Column(
      children: [
        // Class dropdown
        DropdownButtonFormField<Map<String, dynamic>>(
          value: _selectedClass,
          hint: Text('Choose class to modify…', style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14)),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
          style: GoogleFonts.inter(color: const Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 14),
          items: provider.classes.map((cls) => DropdownMenuItem<Map<String, dynamic>>(
            value: cls,
            child: Text('${cls['className'] ?? ''} (${cls['classCode'] ?? ''})'),
          )).toList(),
          onChanged: _onClassSelected,
        ),

        if (_selectedClass != null) ...[
          const SizedBox(height: 12),
          // Subject filter (optional)
          DropdownButtonFormField<Map<String, dynamic>>(
            value: _selectedSubject,
            hint: Text('All Subjects', style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13)),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: GoogleFonts.inter(color: const Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 13),
            items: _subjects.map((s) => DropdownMenuItem<Map<String, dynamic>>(
              value: s,
              child: Text('${s['name'] ?? ''} (${s['code'] ?? ''})'),
            )).toList(),
            onChanged: _subjects.isEmpty ? null : (v) => setState(() => _selectedSubject = v),
          ),
          const SizedBox(height: 12),
          // Summary bar
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_displayClassName, style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
                      Text(
                        '$_displaySubjectName • $presentCount Verified',
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: -0.05),
        ],
      ],
    );
  }

  Widget _buildNoStudents() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), shape: BoxShape.circle),
              child: const Icon(Icons.group_off_rounded, size: 40, color: Color(0xFFCBD5E1)),
            ),
            const SizedBox(height: 16),
            Text('No Students Found', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, color: const Color(0xFF0F172A))),
            const SizedBox(height: 6),
            Text(
              'No students enrolled in this class yet.',
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentList(StaffProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      itemCount: provider.students.length,
      itemBuilder: (_, index) {
        final student = provider.students[index];
        return _studentTile(index, student, provider)
            .animate(delay: (150 + (index * 35)).ms)
            .fadeIn()
            .slideX(begin: 0.05);
      },
    );
  }

  Widget _studentTile(int index, Map<String, dynamic> student, StaffProvider provider) {
    final rawStatus = student['status']?.toString() ?? 'Absent';
    // Normalize: "PRESENT" -> "Present"
    final status = rawStatus.isNotEmpty
        ? '${rawStatus[0].toUpperCase()}${rawStatus.substring(1).toLowerCase()}'
        : 'Absent';
    final displayStatus = _statusOptions.contains(status) ? status : 'Absent';
    final color = _statusColor(displayStatus);

    // Get display name/roll from varying API formats
    final name = student['name']?.toString() ?? student['studentName']?.toString() ?? '—';
    final roll = student['rollNo']?.toString() ?? student['roll']?.toString() ?? student['studentId']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: const Color(0xFF1E293B).withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Center(
              child: Text(
                '${index + 1}',
                style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w900, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF1E293B))),
                if (roll.isNotEmpty)
                  Text(roll, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: displayStatus,
                items: _statusOptions.map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: _statusColor(s))),
                )).toList(),
                onChanged: (val) {
                  setState(() {
                    provider.students[index]['status'] = val?.toUpperCase();
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionFooter(StaffProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('DISCARD', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: const Color(0xFF94A3B8), letterSpacing: 1.2, fontSize: 12)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: ElevatedButton(
                onPressed: () async {
                  await provider.saveAttendance(provider.students);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Synchronization Complete'),
                      backgroundColor: const Color(0xFF0F172A),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  'COMMIT CHANGES',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 12, letterSpacing: 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present': return const Color(0xFF10B981);
      case 'absent':  return const Color(0xFFEF4444);
      case 'od':      return const Color(0xFF3B82F6);
      default:        return Colors.grey;
    }
  }
}
