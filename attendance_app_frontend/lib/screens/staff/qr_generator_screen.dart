import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
import '../../services/auth_service.dart';
import '../../services/qr_attendance_service.dart';

class QrGeneratorScreen extends StatefulWidget {
  const QrGeneratorScreen({super.key});

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen>
    with SingleTickerProviderStateMixin {
  String? _qrToken;
  bool _loading = false;
  bool _loadingClasses = true;
  int _secondsLeft = 0;
  Timer? _timer;

  List<Map<String, dynamic>> _classes = [];
  Map<String, dynamic>? _selectedClass;
  int selectedPeriod = 1;

  final SocketService _socket = SocketService();
  bool _socketConnected = false;

  @override
  void initState() {
    super.initState();
    _loadClasses();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupSocket();
    });
  }

  void _setupSocket() {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final token = AuthService.getToken() ?? '';
    final userId = auth.user?.id ?? '';

    _socket.connect(token, userId, 'STAFF');
    setState(() => _socketConnected = true);

    // Listen for new student attendance requests
    // tag: 'qr_screen' ensures only one handler is active at a time
    _socket.on('new_request', (data) {
      if (mounted) {
        _showAttendanceRequestPopup(data);
      }
    });
  }

  void _showAttendanceRequestPopup(dynamic data) {
    final String studentName = data['studentName'] ?? 'Student';
    final String classCode = data['classCode'] ?? '';
    final int period = data['period'] is int
        ? data['period']
        : int.tryParse(data['period']?.toString() ?? '1') ?? 1;
    final String requestId = data['_id'] ?? '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AttendanceRequestDialog(
        studentName: studentName,
        classCode: classCode,
        period: period,
        requestId: requestId,
        onApprove: () async {
          Navigator.of(ctx).pop();
          await _handleDecision(requestId, true, studentName);
        },
        onReject: () async {
          Navigator.of(ctx).pop();
          await _handleDecision(requestId, false, studentName);
        },
      ),
    );
  }

  Future<void> _handleDecision(
      String requestId, bool approve, String studentName) async {
    final res = approve
        ? await QrAttendanceService.approveRequest(requestId)
        : await QrAttendanceService.rejectRequest(requestId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve
                ? '✅ Approved attendance for $studentName'
                : '❌ Rejected request from $studentName',
          ),
          backgroundColor:
              approve ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );

      if (res['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${res['message'] ?? 'Unknown error'}'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _loadClasses() async {
    try {
      final res = await ApiService.get('/staff/classes');
      final classes = List<Map<String, dynamic>>.from(res['classes'] ?? []);
      if (mounted) {
        setState(() {
          _classes = classes;
          _selectedClass = classes.isNotEmpty ? classes.first : null;
          _loadingClasses = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingClasses = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _socket.off('new_request');
    super.dispose();
  }

  Future<void> _generateQR() async {
    if (_selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a class first'),
            backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final classCode = _selectedClass!['classCode']?.toString() ?? '';
      final res = await ApiService.get(
        '/attendance/generate-qr?classCode=$classCode&period=$selectedPeriod',
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
        if (mounted) setState(() => _secondsLeft--);
      } else {
        timer.cancel();
        if (mounted) setState(() => _qrToken = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('QR ATTENDANCE',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontSize: 13,
                color: const Color(0xFF0F172A))),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF0F172A), size: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _socketConnected
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _socketConnected
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _socketConnected ? 'LIVE' : 'OFFLINE',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: _socketConnected
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
    if (_loadingClasses) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child:
            const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5))),
      );
    }

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF1E293B).withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings_input_component_rounded,
                  color: Color(0xFF4F46E5), size: 18),
              const SizedBox(width: 10),
              Text('SESSION PARAMETERS',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                      fontSize: 12,
                      letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Target Course',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF64748B))),
              const SizedBox(height: 10),
              _classes.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFDBA74)),
                      ),
                      child: Text(
                          'No classes assigned. Ask admin to assign classes.',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: const Color(0xFF92400E))),
                    )
                  : DropdownButtonFormField<Map<String, dynamic>>(
                      value: _selectedClass,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF94A3B8)),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                                color: Color(0xFF4F46E5), width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                      ),
                      style: GoogleFonts.inter(
                          color: const Color(0xFF1E293B),
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                      items: _classes
                          .map((cls) => DropdownMenuItem<Map<String, dynamic>>(
                                value: cls,
                                child: Text(
                                    '${cls['className'] ?? ''} (${cls['classCode'] ?? ''})'),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedClass = val),
                    ),
            ],
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
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF64748B))),
        const SizedBox(height: 10),
        DropdownButtonFormField<T>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF94A3B8)),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          style: GoogleFonts.inter(
              color: const Color(0xFF1E293B),
              fontWeight: FontWeight.bold,
              fontSize: 14),
          items: items
              .map((i) => DropdownMenuItem(
                  value: i, child: Text(itemLabel?.call(i) ?? i.toString())))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildQRDisplay() {
    return Column(
      children: [
        // Info banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 14, color: Color(0xFF4F46E5)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'When a student scans this QR, a popup will appear here for you to approve or reject',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF4F46E5),
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(48),
            border: Border.all(
                color: const Color(0xFF4F46E5).withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF4F46E5).withOpacity(0.1),
                  blurRadius: 40,
                  spreadRadius: 2)
            ],
          ),
          child: QrImageView(
            data: _qrToken!,
            version: QrVersions.auto,
            size: 240.0,
            eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square, color: Color(0xFF0F172A)),
            dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF4F46E5)),
          ),
        ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 48),
        _buildTimerIndicator(),
        const SizedBox(height: 32),
        TextButton.icon(
          onPressed: _generateQR,
          icon: const Icon(Icons.refresh_rounded, size: 20),
          label: const Text('REGENERATE QR CODE'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF4F46E5),
            textStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                fontSize: 12),
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
          _secondsLeftS,
          style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: warning
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF0F172A),
              letterSpacing: -1),
        ),
        const SizedBox(height: 4),
        Text('TIME TO EXPIRY',
            style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: const Color(0xFF94A3B8))),
        const SizedBox(height: 24),
        Container(
          width: 220,
          height: 6,
          decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10)),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(seconds: 1),
                width: 220 * (_secondsLeft / 60),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: warning
                          ? [const Color(0xFFEF4444), Colors.orange]
                          : [
                              const Color(0xFF4F46E5),
                              const Color(0xFF818CF8)
                            ]),
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
          decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9), shape: BoxShape.circle),
          child: Icon(Icons.qr_code_2_rounded,
              size: 64, color: const Color(0xFFCBD5E1)),
        ),
        const SizedBox(height: 32),
        Text('Ready to Generate',
            style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF475569))),
        const SizedBox(height: 8),
        const Text(
            'Generate a QR code for students to scan and request attendance.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
        const SizedBox(height: 48),
        _buildActionBtn('GENERATE QR CODE', _generateQR),
      ],
    ).animate().fadeIn();
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        const CircularProgressIndicator(
            color: Color(0xFF4F46E5), strokeWidth: 3),
        const SizedBox(height: 24),
        Text('Generating QR Code...',
            style: GoogleFonts.outfit(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ],
    );
  }

  Widget _buildActionBtn(String label, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 62,
      decoration: BoxDecoration(
        color: const Color(0xFF4F46E5),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF4F46E5).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20))),
        child: Text(label,
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontSize: 14,
                letterSpacing: 1)),
      ),
    );
  }
}

// ─── Popup Dialog for incoming attendance requests ────────────────────────────
class _AttendanceRequestDialog extends StatelessWidget {
  final String studentName;
  final String classCode;
  final int period;
  final String requestId;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _AttendanceRequestDialog({
    required this.studentName,
    required this.classCode,
    required this.period,
    required this.requestId,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F46E5).withOpacity(0.15),
              blurRadius: 40,
              spreadRadius: 4,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated pulse icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.person_pin_rounded,
                  color: Colors.white, size: 36),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 1.0, end: 1.08, duration: 800.ms),
            const SizedBox(height: 20),
            Text(
              'Attendance Request',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              studentName,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.class_rounded,
                      size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Text(
                    classCode.isNotEmpty ? classCode : 'General',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.schedule_rounded,
                      size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Text(
                    'Period $period',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'wants to mark attendance',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                // Reject button
                Expanded(
                  child: TextButton(
                    onPressed: onReject,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(
                            color: Color(0xFFEF4444), width: 1.5),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cancel_rounded, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Reject',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w900, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Approve button
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Approve',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w900, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      )
          .animate()
          .scale(begin: const Offset(0.8, 0.8), duration: 300.ms, curve: Curves.easeOutBack)
          .fadeIn(duration: 200.ms),
    );
  }
}
