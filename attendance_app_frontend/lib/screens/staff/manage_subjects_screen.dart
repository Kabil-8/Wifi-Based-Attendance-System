import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/staff_provider.dart';

class ManageSubjectsScreen extends StatefulWidget {
  const ManageSubjectsScreen({super.key});

  @override
  State<ManageSubjectsScreen> createState() => _ManageSubjectsScreenState();
}

class _ManageSubjectsScreenState extends State<ManageSubjectsScreen> {
  Map<String, dynamic>? _selectedClass;
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _dayController = TextEditingController();
  final _timeController = TextEditingController();
  final _roomController = TextEditingController();
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
    _codeController.dispose();
    _nameController.dispose();
    _dayController.dispose();
    _timeController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  void _onClassSelected(Map<String, dynamic>? cls) {
    if (cls == null) return;
    setState(() => _selectedClass = cls);
    context.read<StaffProvider>().loadSubjects(cls['_id'].toString());
  }

  Future<void> _addSubject() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClass == null) {
      _showSnack('Please select a class first', Colors.orange);
      return;
    }

    setState(() => _saving = true);

    final provider = context.read<StaffProvider>();
    final error = await provider.addSubject(
      _selectedClass!['_id'].toString(),
      _codeController.text.trim().toUpperCase(),
      _nameController.text.trim(),
      schedule: {
        'day': _dayController.text.trim(),
        'time': _timeController.text.trim(),
        'room': _roomController.text.trim(),
      },
    );

    setState(() => _saving = false);
    if (!mounted) return;

    if (error == null) {
      _codeController.clear();
      _nameController.clear();
      _dayController.clear();
      _timeController.clear();
      _roomController.clear();
      _showSnack('Subject added successfully!', const Color(0xFF10B981));
    } else {
      _showSnack('Failed: $error', const Color(0xFFEF4444));
    }
  }

  Future<void> _deleteSubject(String subjectCode) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Subject', style: GoogleFonts.inter(fontWeight: FontWeight.w900)),
        content: Text(
          'Remove "$subjectCode" from this class?',
          style: GoogleFonts.inter(color: const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || _selectedClass == null) return;

    final provider = context.read<StaffProvider>();
    final error = await provider.deleteSubject(
      _selectedClass!['_id'].toString(),
      subjectCode,
    );

    if (!mounted) return;
    if (error == null) {
      _showSnack('Subject deleted', const Color(0xFF10B981));
    } else {
      _showSnack('Failed: $error', const Color(0xFFEF4444));
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final staff = context.watch<StaffProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'MANAGE SUBJECTS',
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
      body: staff.loading && staff.classes.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              children: [
                // Class Selector
                _buildClassSelector(staff),
                const SizedBox(height: 24),

                // Subject List
                if (_selectedClass != null) ...[
                  _buildSubjectList(staff),
                  const SizedBox(height: 24),
                  _buildAddSubjectForm(),
                ],
              ],
            ),
    );
  }

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
              Text('Select Class', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 15, color: const Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 20),
          staff.classes.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDBA74)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFF97316), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No classes assigned. Ask admin to assign classes to you.',
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF92400E)),
                        ),
                      ),
                    ],
                  ),
                )
              : DropdownButtonFormField<Map<String, dynamic>>(
                  value: _selectedClass,
                  hint: Text('Choose a class…', style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14)),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  ),
                  style: GoogleFonts.inter(color: const Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 14),
                  items: staff.classes.map((cls) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: cls,
                      child: Text('${cls['className'] ?? 'Class'} (${cls['classCode'] ?? ''})'),
                    );
                  }).toList(),
                  onChanged: _onClassSelected,
                ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.08);
  }

  Widget _buildSubjectList(StaffProvider staff) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1E293B).withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.book_rounded, color: Color(0xFF7C3AED), size: 18),
                ),
                const SizedBox(width: 12),
                Text('Subjects', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 15, color: const Color(0xFF0F172A))),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${staff.subjects.length}',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF4F46E5)),
                  ),
                ),
              ],
            ),
          ),
          if (staff.loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5), strokeWidth: 2)),
            )
          else if (staff.subjects.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Text(
                'No subjects added yet. Add your first subject below.',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8), height: 1.5),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: staff.subjects.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final sub = staff.subjects[i];
                return _buildSubjectTile(sub);
              },
            ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.08);
  }

  Widget _buildSubjectTile(Map<String, dynamic> sub) {
    final code = sub['code']?.toString() ?? '';
    final name = sub['name']?.toString() ?? '';
    final schedule = sub['schedule'] as Map<String, dynamic>?;
    final day = schedule?['day']?.toString() ?? '';
    final time = schedule?['time']?.toString() ?? '';
    final room = schedule?['room']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                code.isNotEmpty ? code.substring(0, code.length.clamp(0, 3)) : 'S',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w900, color: const Color(0xFF4F46E5)),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 14, color: const Color(0xFF0F172A))),
                Text(
                  code + (day.isNotEmpty ? ' · $day' : '') + (time.isNotEmpty ? ' $time' : '') + (room.isNotEmpty ? ' · $room' : ''),
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _deleteSubject(code),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddSubjectForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF10B981).withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 6)),
        ],
      ),
      child: Form(
        key: _formKey,
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
                  child: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF10B981), size: 18),
                ),
                const SizedBox(width: 12),
                Text('Add New Subject', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 15, color: const Color(0xFF0F172A))),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildInput(
                    controller: _codeController,
                    label: 'Subject Code',
                    hint: 'e.g. CS101',
                    icon: Icons.tag_rounded,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: _buildInput(
                    controller: _nameController,
                    label: 'Subject Name',
                    hint: 'e.g. Data Structures',
                    icon: Icons.book_outlined,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'SCHEDULE (OPTIONAL)',
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF94A3B8), letterSpacing: 1),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInput(controller: _dayController, label: 'Day', hint: 'Mon', icon: Icons.calendar_today_rounded),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildInput(controller: _timeController, label: 'Time', hint: '9:00 AM', icon: Icons.access_time_rounded),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildInput(controller: _roomController, label: 'Room', hint: 'A101', icon: Icons.door_front_door_rounded),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saving ? null : _addSubject,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'ADD SUBJECT',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 13, letterSpacing: 0.8),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.08);
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B), fontSize: 13),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
        hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFCBD5E1)),
        prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 18),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
