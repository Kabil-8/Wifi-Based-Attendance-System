import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/socket_service.dart';
import '../../services/qr_attendance_service.dart';
import '../../services/auth_service.dart';

class QrScanRequestScreen extends StatefulWidget {
  const QrScanRequestScreen({super.key});

  @override
  State<QrScanRequestScreen> createState() => _QrScanRequestScreenState();
}

class _QrScanRequestScreenState extends State<QrScanRequestScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  final SocketService _socket = SocketService();
  
  bool _isProcessing = false;
  bool _isScanned = false;
  String _status = 'SCANNING'; // SCANNING, PENDING, APPROVED, REJECTED
  String _message = 'Align the QR code within the frame';
  String? _requestId;

  @override
  void initState() {
    super.initState();
    _setupSocket();
  }

  void _setupSocket() {
    final auth = context.read<AuthProvider>();
    final token = AuthService.getToken() ?? '';
    final userId = auth.user?.id ?? '';
    
    _socket.connect(token, userId, 'STUDENT');

    _socket.on('request_approved', (data) {
      if (mounted && _status == 'PENDING') {
        setState(() {
          _status = 'APPROVED';
          _message = 'Attendance marked successfully!';
        });
      }
    });

    _socket.on('request_rejected', (data) {
      if (mounted && _status == 'PENDING') {
        setState(() {
          _status = 'REJECTED';
          _message = 'Teacher rejected your request.';
        });
      }
    });
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing || _isScanned) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      if (barcode.rawValue != null) {
        setState(() {
          _isProcessing = true;
          _isScanned = true;
          _status = 'PENDING';
          _message = 'Request sent... waiting for teacher approval.';
        });
        
        _scannerController.stop();

        final studentId = context.read<AuthProvider>().user?.id ?? '';
        final res = await QrAttendanceService.requestAttendance(
          token: barcode.rawValue!,
          studentId: studentId,
        );

        if (res['success'] == true) {
          if (mounted) {
             _requestId = res['data']['_id'];
             setState(() => _isProcessing = false);
          }
        } else {
          if (mounted) {
            setState(() {
              _status = 'ERROR';
              _message = res['message'] ?? 'Failed to send request';
              _isProcessing = false;
            });
          }
        }
      }
    }
  }

  void _resetScanner() {
    setState(() {
      _isScanned = false;
      _isProcessing = false;
      _status = 'SCANNING';
      _message = 'Align the QR code within the frame';
    });
    _scannerController.start();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('SCAN QR', 
          style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13, color: const Color(0xFF0F172A))),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 6,
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF1E293B).withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 15))
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: _status == 'SCANNING'
                    ? MobileScanner(
                        controller: _scannerController,
                        onDetect: _handleBarcode,
                      )
                    : _buildStatusView(),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _status == 'REJECTED' || _status == 'ERROR' ? Colors.red : 
                           _status == 'APPROVED' ? Colors.green : const Color(0xFF64748B),
                  ),
                ).animate(target: _status == 'REJECTED' ? 1 : 0).shake(),
              ),
            ),
          ),
          if (_status != 'SCANNING' && _status != 'PENDING')
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: ElevatedButton.icon(
                onPressed: _resetScanner,
                icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                label: Text('Scan Again', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildStatusView() {
    Color bgColor = Colors.white;
    IconData icon = Icons.hourglass_empty;
    Color iconColor = Colors.orange;

    if (_status == 'APPROVED') {
      icon = Icons.check_circle;
      iconColor = const Color(0xFF10B981);
    } else if (_status == 'REJECTED' || _status == 'ERROR') {
      icon = Icons.cancel;
      iconColor = const Color(0xFFEF4444);
    }

    return Container(
      color: bgColor,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_status == 'PENDING')
            const CircularProgressIndicator(color: Colors.orange)
          else
            Icon(icon, size: 80, color: iconColor).animate().scale().fadeIn(),
          const SizedBox(height: 24),
          Text(
            _status,
            style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: iconColor, letterSpacing: 1.5),
          )
        ],
      ),
    );
  }
}
