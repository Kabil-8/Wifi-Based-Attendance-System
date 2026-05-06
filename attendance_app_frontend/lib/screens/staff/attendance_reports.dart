import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/api_service.dart';

class AttendanceReports extends StatefulWidget {
  const AttendanceReports({super.key});

  @override
  State<AttendanceReports> createState() => _AttendanceReportsState();
}

class _AttendanceReportsState extends State<AttendanceReports> {
  // Dynamic data from API
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _subjects = [];

  Map<String, dynamic>? _selectedClass;
  Map<String, dynamic>? _selectedSubject;
  String _reportType = 'Overall Attendance';
  DateTime? _fromDate;
  DateTime? _toDate;

  bool _loadingClasses = true;
  bool _loadingReport = false;
  Map<String, dynamic>? _summary;
  List<dynamic> _studentRecords = [];

  final List<String> _reportTypes = [
    'Overall Attendance',
    'Student Wise',
    'Date Wise',
    'Defaulters List',
  ];

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      setState(() => _loadingClasses = true);
      final res = await ApiService.get('/reports/classes');
      final classes = List<Map<String, dynamic>>.from(res['classes'] ?? []);
      setState(() {
        _classes = classes;
        _loadingClasses = false;
      });
    } catch (e) {
      setState(() => _loadingClasses = false);
      _showSnack('Failed to load classes: $e', const Color(0xFFEF4444));
    }
  }

  void _onClassChanged(Map<String, dynamic>? cls) {
    if (cls == null) return;
    final subjects = List<Map<String, dynamic>>.from(
      (cls['subjects'] as List? ?? []).map((s) => Map<String, dynamic>.from(s as Map)),
    );
    setState(() {
      _selectedClass = cls;
      _subjects = subjects;
      _selectedSubject = null;
      _summary = null;
      _studentRecords = [];
    });
  }

  Future<void> _loadReport() async {
    if (_selectedClass == null) {
      _showSnack('Please select a class first', Colors.orange);
      return;
    }
    try {
      setState(() => _loadingReport = true);

      final classId = _selectedClass!['_id']?.toString() ?? '';
      final subjectCode = _selectedSubject?['code']?.toString() ?? '';
      final fromStr = _fromDate?.toIso8601String().split('T')[0] ?? '';
      final toStr = _toDate?.toIso8601String().split('T')[0] ?? '';

      String query = '/reports/summary?classId=$classId';
      if (subjectCode.isNotEmpty) query += '&subjectCode=$subjectCode';
      if (fromStr.isNotEmpty) query += '&from=$fromStr';
      if (toStr.isNotEmpty) query += '&to=$toStr';

      final res = await ApiService.get(query);
      setState(() {
        _summary = Map<String, dynamic>.from(res);
        _loadingReport = false;
      });

      // Load student records for Student Wise / Defaulters
      if (_reportType == 'Student Wise' || _reportType == 'Defaulters List') {
        await _loadStudentRecords(classId, subjectCode, fromStr);
      }
    } catch (e) {
      setState(() => _loadingReport = false);
      _showSnack('Failed to load report: $e', const Color(0xFFEF4444));
    }
  }

  Future<void> _loadStudentRecords(String classId, String subject, String date) async {
    try {
      String query = '/reports/students?classId=$classId';
      if (subject.isNotEmpty) query += '&subject=$subject';
      if (date.isNotEmpty) query += '&date=$date';

      final res = await ApiService.get(query);
      setState(() {
        _studentRecords = res['records'] ?? [];
      });
    } catch (_) {}
  }

  Future<void> _selectDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF4F46E5)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => isFrom ? _fromDate = picked : _toDate = picked);
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'ATTENDANCE REPORTS',
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
      body: _loadingClasses
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                children: [
                  _buildFilterPanel(),
                  const SizedBox(height: 24),
                  _buildGenerateButton(),
                  const SizedBox(height: 28),
                  if (_loadingReport)
                    const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
                  else if (_summary != null) ...[
                    _buildSummaryCards(),
                    const SizedBox(height: 24),
                    if (_studentRecords.isNotEmpty) _buildStudentTable(),
                  ] else
                    _buildEmptyState(),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.filter_list_rounded, color: Color(0xFF4F46E5), size: 18),
              ),
              const SizedBox(width: 12),
              Text('Report Filters', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 15, color: const Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 20),

          // Class dropdown
          _buildLabel('Class'),
          const SizedBox(height: 8),
          DropdownButtonFormField<Map<String, dynamic>>(
            value: _selectedClass,
            hint: Text('Select class…', style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14)),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
            decoration: _dropdownDec(),
            style: GoogleFonts.inter(color: const Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 14),
            items: _classes.map((cls) => DropdownMenuItem<Map<String, dynamic>>(
              value: cls,
              child: Text('${cls['className'] ?? ''} (${cls['classCode'] ?? ''})'),
            )).toList(),
            onChanged: _onClassChanged,
          ),

          const SizedBox(height: 16),

          // Subject dropdown (dynamic based on class)
          _buildLabel('Subject'),
          const SizedBox(height: 8),
          DropdownButtonFormField<Map<String, dynamic>>(
            value: _selectedSubject,
            hint: Text(
              _subjects.isEmpty ? 'Select a class first…' : 'All Subjects',
              style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14),
            ),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
            decoration: _dropdownDec(),
            style: GoogleFonts.inter(color: const Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 14),
            items: _subjects.map((s) => DropdownMenuItem<Map<String, dynamic>>(
              value: s,
              child: Text('${s['name'] ?? ''} (${s['code'] ?? ''})'),
            )).toList(),
            onChanged: _subjects.isEmpty ? null : (v) => setState(() => _selectedSubject = v),
          ),

          const SizedBox(height: 16),

          // Report type
          _buildLabel('Report Type'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _reportType,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
            decoration: _dropdownDec(),
            style: GoogleFonts.inter(color: const Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 14),
            items: _reportTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _reportType = v!),
          ),

          const SizedBox(height: 16),

          // Date range
          _buildLabel('Date Range (Optional)'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildDatePicker('From', _fromDate, () => _selectDate(true))),
              const SizedBox(width: 12),
              Expanded(child: _buildDatePicker('To', _toDate, () => _selectDate(false))),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.08);
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)], begin: Alignment.centerLeft, end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: ElevatedButton(
          onPressed: _loadingReport ? null : _loadReport,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
          child: _loadingReport
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.analytics_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text('GENERATE REPORT', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 13, letterSpacing: 1)),
                  ],
                ),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildSummaryCards() {
    final s = _summary!;
    final items = [
      {'label': 'Total Records', 'value': '${s['total'] ?? 0}', 'color': const Color(0xFF4F46E5), 'icon': Icons.people_alt_rounded},
      {'label': 'Present', 'value': '${s['present'] ?? 0}', 'color': const Color(0xFF10B981), 'icon': Icons.check_circle_rounded},
      {'label': 'Absent', 'value': '${s['absent'] ?? 0}', 'color': const Color(0xFFEF4444), 'icon': Icons.cancel_rounded},
      {'label': 'Avg Attendance', 'value': '${s['average'] ?? 0}%', 'color': const Color(0xFF3B82F6), 'icon': Icons.percent_rounded},
      {'label': '≥ 75%', 'value': '${s['above75'] ?? 0}', 'color': const Color(0xFF10B981), 'icon': Icons.verified_rounded},
      {'label': 'Defaulters', 'value': '${s['defaulters'] ?? 0}', 'color': const Color(0xFFF97316), 'icon': Icons.warning_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Summary', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, color: const Color(0xFF0F172A))),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final item = items[i];
            final color = item['color'] as Color;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(item['icon'] as IconData, color: color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item['value'] as String, style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 20, color: const Color(0xFF0F172A))),
                      Text(item['label'] as String, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ).animate(delay: (i * 60).ms).fadeIn().slideY(begin: 0.08);
          },
        ),
      ],
    );
  }

  Widget _buildStudentTable() {
    final isDefaulters = _reportType == 'Defaulters List';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isDefaulters ? 'Defaulters (< 75%)' : 'Student Records',
          style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: _studentRecords.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
            itemBuilder: (_, i) {
              final r = _studentRecords[i] as Map<String, dynamic>;
              final status = r['status']?.toString() ?? 'ABSENT';
              final color = status == 'PRESENT' ? const Color(0xFF10B981) : status == 'OD' ? const Color(0xFF3B82F6) : const Color(0xFFEF4444);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r['studentName']?.toString() ?? '—', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(r['date']?.toString() ?? '', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(status, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: color)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), shape: BoxShape.circle),
            child: const Icon(Icons.bar_chart_rounded, size: 48, color: Color(0xFFCBD5E1)),
          ),
          const SizedBox(height: 20),
          Text('No Report Generated', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, color: const Color(0xFF475569))),
          const SizedBox(height: 8),
          Text(
            'Select a class and click "Generate Report" to view attendance analytics.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8), height: 1.5),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  // ---------- Helpers ----------

  Widget _buildLabel(String text) {
    return Text(text, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w900, color: const Color(0xFF64748B), letterSpacing: 0.5));
  }

  InputDecoration _dropdownDec() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildDatePicker(String label, DateTime? date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF94A3B8)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date == null ? label : '${date.day}/${date.month}/${date.year}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: date == null ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
