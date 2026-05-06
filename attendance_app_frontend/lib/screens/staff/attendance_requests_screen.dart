import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/socket_service.dart';
import '../../services/qr_attendance_service.dart';
import '../../services/auth_service.dart';

class AttendanceRequestsScreen extends StatefulWidget {
  const AttendanceRequestsScreen({super.key});

  @override
  State<AttendanceRequestsScreen> createState() => _AttendanceRequestsScreenState();
}

class _AttendanceRequestsScreenState extends State<AttendanceRequestsScreen> {
  final SocketService _socket = SocketService();
  List<dynamic> _pendingRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
    _setupSocket();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    final res = await QrAttendanceService.getPendingRequests();
    if (res['success'] == true) {
      if (mounted) {
        setState(() {
          _pendingRequests = res['data'] ?? [];
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setupSocket() {
    final auth = context.read<AuthProvider>();
    final token = AuthService.getToken() ?? '';
    final userId = auth.user?.id ?? '';
    
    // Connect to room if not connected
    _socket.connect(token, userId, 'STAFF');

    _socket.on('new_request', (data) {
      if (mounted) {
        setState(() {
          _pendingRequests.insert(0, data);
        });
        _showRequestPopup(data);
      }
    });
  }

  void _showRequestPopup(dynamic data) {
    final String studentName = data['studentName'] ?? 'Student';
    final String classCode = data['classCode'] ?? '';
    final int period = data['period'] is int
        ? data['period']
        : int.tryParse(data['period']?.toString() ?? '1') ?? 1;
    final String requestId = data['_id'] ?? '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
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
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
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
              ).animate(onPlay: (c) => c.repeat(reverse: true))
               .scaleXY(begin: 1.0, end: 1.08, duration: 800.ms),
              const SizedBox(height: 20),
              Text(
                'ATTENDANCE REQUEST',
                style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w900,
                  letterSpacing: 1.5, color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                studentName,
                style: GoogleFonts.inter(
                  fontSize: 22, fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${classCode.isNotEmpty ? classCode : 'General'}  •  Period $period',
                  style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.bold,
                    color: const Color(0xFF334155),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text('wants to mark attendance',
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _handleDecision(requestId, false);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                        ),
                      ),
                      child: Text('Reject',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _handleDecision(requestId, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Approve',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate()
         .scale(begin: const Offset(0.8, 0.8), duration: 300.ms, curve: Curves.easeOutBack)
         .fadeIn(duration: 200.ms),
      ),
    );
  }


  Future<void> _handleDecision(String requestId, bool approve) async {
    // Optimistic UI update
    final idx = _pendingRequests.indexWhere((r) => r['_id'] == requestId);
    if (idx != -1) {
      setState(() => _pendingRequests.removeAt(idx));
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(approve ? 'Request Approved' : 'Request Rejected'),
        backgroundColor: approve ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        duration: const Duration(seconds: 2),
      ),
    );

    final res = approve
        ? await QrAttendanceService.approveRequest(requestId)
        : await QrAttendanceService.rejectRequest(requestId);

    if (res['success'] != true && mounted) {
      // Revert if failed
      _fetchRequests();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${res['message']}'), backgroundColor: Colors.orange),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('PENDING REQUESTS', 
          style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13, color: const Color(0xFF0F172A))),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFF1F5F9)),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
        : _pendingRequests.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No Pending Requests', style: GoogleFonts.inter(color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ).animate().fadeIn()
            )
          : RefreshIndicator(
              onRefresh: _fetchRequests,
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _pendingRequests.length,
                itemBuilder: (context, index) {
                  final req = _pendingRequests[index];
                  return _buildRequestCard(req).animate().slideX(begin: 0.1).fadeIn();
                },
              ),
            ),
    );
  }

  Widget _buildRequestCard(dynamic req) {
    String name = req['studentName'] ?? 'Unknown';
    String initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    String classCode = req['classCode'] ?? 'Gen';
    int period = req['period'] ?? 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1E293B).withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF4F46E5).withOpacity(0.1),
            radius: 24,
            child: Text(initial, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF4F46E5))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF0F172A))),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                  child: Text('$classCode | Period $period', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _handleDecision(req['_id'], true),
            icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 36),
          ),
          IconButton(
            onPressed: () => _handleDecision(req['_id'], false),
            icon: const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 36),
          ),
        ],
      ),
    );
  }
}
