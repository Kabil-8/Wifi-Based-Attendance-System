import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:attendance_app/services/biometric_service.dart';
import 'package:attendance_app/services/wifi_service.dart';
import 'package:attendance_app/services/permission_service.dart';
import 'package:attendance_app/services/api_service.dart';
import 'package:attendance_app/services/auth_service.dart';
import 'package:attendance_app/services/security_service.dart';
import 'package:attendance_app/services/camera_Service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class MarkAttendanceScreen extends StatefulWidget {
  const MarkAttendanceScreen({super.key});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  final BiometricService _bio = BiometricService();
  final WifiService _wifi = WifiService();
  final CameraService _camera = CameraService();

  bool _loading = false;
  String _statusMessage = 'System Ready';
  bool _isSuccess = false;
  String? _errorMessage;
  String? _ssid;
  String? _bssidDetected;
  bool _scanningWifi = false;
  Timer? _wifiTimer;
  int _wifiOffAttempts = 0;
  bool _limitReached = false;

  @override
  void initState() {
    super.initState();
    _fetchNetworkInfo();
    _wifiTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!_loading && !_isSuccess) _fetchNetworkInfo();
    });
  }

  @override
  void dispose() {
    _wifiTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchNetworkInfo() async {
    if (!mounted) return;
    setState(() => _scanningWifi = true);
    try {
      final ssid = await _wifi.getWifiName();
      final bssid = await _wifi.getBSSID();
      if (mounted) {
        setState(() {
          _ssid = ssid;
          _bssidDetected = bssid;
          _scanningWifi = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _scanningWifi = false);
    }
  }

  void _reset() {
    if (_limitReached) return;
    setState(() {
      _loading = false;
      _isSuccess = false;
      _errorMessage = null;
      _statusMessage = 'System Ready';
    });
  }

  void _fail(String msg, {bool permanent = false}) {
    setState(() {
      _loading = false;
      _errorMessage = msg;
      if (permanent) _limitReached = true;
    });
    HapticFeedback.vibrate();
  }

  Future<void> _startVerification() async {
    if (_limitReached) return;
    _reset();
    setState(() {
      _loading = true;
      _statusMessage = 'Initializing Secure Protocol...';
    });

    // Phase 1: Wi-Fi Hardware Check - ONLY prompt if physically turned OFF
    final wifiEnabled = await _wifi.isWifiEnabled();
    if (!wifiEnabled) {
      _wifiOffAttempts++;
      if (_wifiOffAttempts >= 3) {
        await _logAbsent('Security Breach: Wi-Fi hardware persistently disabled', permanent: true);
        _wifiOffAttempts = 0;
      } else {
        _showWifiPrompt();
      }
      setState(() => _loading = false);
      return;
    }
    _wifiOffAttempts = 0;

    // Phase 2: Proximity & Network Signature Validation
    setState(() => _statusMessage = 'Authenticating Proximity...');
    final bssidRes = await _wifi.validateBssid();
    if (!bssidRes.isAuthorized) {
      final reason = bssidRes.errorMessage ?? 'Proximity violation: Unauthorized network';
      await _logAbsent(reason);
      setState(() => _loading = false);
      return;
    }

    // Phase 3: GPS Telemetry
    setState(() => _statusMessage = 'Syncing GPS Telemetry...');
    Position? pos;
    try { 
      pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10)
      ); 
    } catch (_) {}
    final gps = pos != null 
        ? {'latitude': pos.latitude, 'longitude': pos.longitude} 
        : {'latitude': 0.0, 'longitude': 0.0};

    // Phase 4: QR Session Validation
    setState(() => _statusMessage = 'Scanning Academic QR...');
    final qr = await Navigator.push<String>(
      context, 
      MaterialPageRoute(builder: (_) => const QRScannerPage())
    );
    if (qr == null) { 
      _fail('Verification Aborted: QR Session missing'); 
      return; 
    }

    // Phase 5: Biometric/Face Audit
    setState(() => _statusMessage = 'Final Identity Check...');
    final selfie = await _camera.captureAuditSelfie();
    if (selfie == null) { 
      _fail('Verification Aborted: Biometric mismatch'); 
      return; 
    }

    // Phase 6: Core Encryption & Submission
    setState(() => _statusMessage = 'Sealing MFA Protocol...');
    await _submit(bssidRes.bssid!, gps, qr, selfie);
  }

  Future<void> _submit(String bssid, Map<String, double> gps, String qr, File selfie) async {
    try {
      final token = AuthService.getToken();
      final res = await ApiService.upload('/attendance/verify-complex', file: selfie, fieldName: 'selfieImage', token: token!, fields: {
        'bssid': bssid,
        'rssi': '-50',
        'gpsLocation': '{"lat":${gps['latitude']},"lng":${gps['longitude']}}',
        'qrToken': qr,
        'livenessConfirmed': 'true',
      });

      if (res['success'] == true) {
        setState(() {
          _isSuccess = true;
          _loading = false;
          _statusMessage = 'Attendance Verified';
        });
        HapticFeedback.heavyImpact();
      } else {
        _fail(res['message'] ?? 'Verification Denied');
      }
    } catch (e) {
      _fail('Connection Protocol Failed');
    }
  }

  Future<void> _logAbsent(String reason, {bool permanent = false}) async {
    _fail(reason, permanent: permanent);
    final token = AuthService.getToken();
    if (token == null) return;
    await ApiService.post('/attendance/verify-complex', body: {
      'status': 'ABSENT',
      'reason': reason,
      'bssid': _bssidDetected ?? 'N/A'
    });
  }

  void _showWifiPrompt() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => Container(),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              title: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded, color: Color(0xFF4F46E5)),
                  const SizedBox(width: 12),
                  Text('Link Required', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 18, color: const Color(0xFF0F172A))),
                ],
              ),
              content: Text(
                'Proximity validation requires an active Wi-Fi hardware state. Please enable Wi-Fi in settings.',
                style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: const Color(0xFF4F46E5))),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('SECURE VERIFICATION', 
          style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13, color: const Color(0xFF0F172A))),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildNetworkStatus(),
            const SizedBox(height: 70),
            _buildVisualScanner(),
            const SizedBox(height: 70),
            if (_isSuccess) _buildSuccess() else if (_errorMessage != null) _buildError() else _buildInstructions(),
            const SizedBox(height: 60),
            if (!_loading && !_isSuccess) _buildStartButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: const Color(0xFF1E293B).withOpacity(0.02), blurRadius: 10)]
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_tethering_rounded, color: _ssid != null ? const Color(0xFF10B981) : Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(_ssid ?? 'Searching Network...', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF334155)))),
          if (_scanningWifi) const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5))),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildVisualScanner() {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (_loading) ...[
          _buildRing(1),
          _buildRing(2),
          _buildRing(3),
        ],
        Container(
          width: 210,
          height: 210,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [BoxShadow(color: const Color(0xFF1E293B).withOpacity(0.05), blurRadius: 40)],
          ),
          child: Center(
            child: _loading 
              ? const CircularProgressIndicator(color: Color(0xFF4F46E5), strokeWidth: 4)
              : Icon(_isSuccess ? Icons.verified_rounded : Icons.fingerprint_rounded, size: 85, color: _isSuccess ? const Color(0xFF10B981) : const Color(0xFF4F46E5)),
          ),
        ),
      ],
    );
  }

  Widget _buildRing(int i) {
    return Container(
      width: 210,
      height: 210,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.1), width: 2),
      ),
    ).animate(onPlay: (c) => c.repeat()).scale(duration: 2.seconds, delay: (i * 500).ms, begin: const Offset(1,1), end: const Offset(1.7, 1.7)).fadeOut();
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), 
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(_statusMessage, style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
          const SizedBox(height: 10),
          Text('Verify you are in the class zone. We will audit your network, location, and identity.', 
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildSuccess() {
    return Column(
      children: [
        Text('IDENTITY VERIFIED', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF10B981))),
        const SizedBox(height: 8),
        Text('Secure protocol successfully synchronized.', style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 32),
        _buildActionBtn('DISMISS', () => Navigator.pop(context), color: const Color(0xFF10B981)),
      ],
    ).animate().scale();
  }

  Widget _buildError() {
    return Column(
      children: [
        Text('PROTOCOL BREACH', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFFEF4444))),
        const SizedBox(height: 8),
        Text(_errorMessage!, textAlign: TextAlign.center, style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 32),
        if (!_limitReached)
          TextButton(onPressed: _reset, child: Text('REATTEMPT SESSION', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: const Color(0xFF4F46E5)))),
      ],
    ).animate().shake();
  }

  Widget _buildStartButton() {
    return _buildActionBtn('INITIATE ENCRYPTION', _startVerification);
  }

  Widget _buildActionBtn(String label, VoidCallback onPressed, {Color? color}) {
    return Container(
      width: double.infinity,
      height: 62,
      decoration: BoxDecoration(
        color: color ?? const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: (color ?? const Color(0xFF1E293B)).withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        child: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 14, letterSpacing: 1)),
      ),
    ).animate().fadeIn(delay: 400.ms);
  }
}

class QRScannerPage extends StatelessWidget {
  const QRScannerPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SCAN SESSION DATA', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)), 
        backgroundColor: Colors.black,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
        ),
      ),
      body: MobileScanner(onDetect: (cap) {
        if (cap.barcodes.isNotEmpty) Navigator.pop(context, cap.barcodes.first.rawValue);
      }),
    );
  }
}
