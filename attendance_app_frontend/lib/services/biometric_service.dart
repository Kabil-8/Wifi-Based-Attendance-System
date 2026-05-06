import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

/// Result of a biometric authentication attempt.
class BiometricResult {
  final bool success;
  final String? errorMessage;
  final String method; // "fingerprint" or "face" — for audit trail

  const BiometricResult({
    required this.success,
    this.errorMessage,
    this.method = 'biometric',
  });
}

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// ── Tier 3A: Standard Fingerprint Authentication ─────────────────────────
  ///
  /// Used when biometric signatures MATCH (no changes detected).
  /// Fast path — the "Good Day" scenario.
  Future<BiometricResult> authenticateFingerprint() async {
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool isSupported = await _auth.isDeviceSupported();

      if (!canCheck || !isSupported) {
        return const BiometricResult(
          success: false,
          method: 'fingerprint',
          errorMessage: 'Identity Verification Failed: '
              'No biometric hardware available on this device.',
        );
      }

      final List<BiometricType> enrolled = await _auth.getAvailableBiometrics();

      if (enrolled.isEmpty) {
        return const BiometricResult(
          success: false,
          method: 'fingerprint',
          errorMessage: 'Identity Verification Failed: '
              'No biometrics enrolled. Please enrol fingerprint in device settings.',
        );
      }

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Scan your fingerprint to mark attendance',
        options: const AuthenticationOptions(
          biometricOnly: true,  // No PIN/pattern fallback
          stickyAuth: true,     // Keep prompt alive when app goes to background
          sensitiveTransaction: true,
        ),
      );

      if (!didAuthenticate) {
        return const BiometricResult(
          success: false,
          method: 'fingerprint',
          errorMessage: 'Identity Verification Failed',
        );
      }

      return const BiometricResult(success: true, method: 'fingerprint');
    } on PlatformException catch (e) {
      final reason = _mapPlatformError(e.code);
      return BiometricResult(
        success: false,
        method: 'fingerprint',
        errorMessage: 'Identity Verification Failed: $reason',
      );
    } catch (e) {
      return BiometricResult(
        success: false,
        method: 'fingerprint',
        errorMessage: 'Identity Verification Failed: ${e.toString()}',
      );
    }
  }

  /// ── Legacy: General authentication (backward compatible) ─────────────────
  ///
  /// Verifies the user's identity using the strongest available biometric.
  Future<BiometricResult> authenticate() async {
    return authenticateFingerprint();
  }

  String _mapPlatformError(String code) {
    switch (code) {
      case 'LockedOut':
        return 'Too many failed attempts. Try again later.';
      case 'PermanentlyLockedOut':
        return 'Biometrics permanently locked. Please use device PIN.';
      case 'NotAvailable':
        return 'Biometrics not available on this device.';
      case 'NotEnrolled':
        return 'No biometrics enrolled in device settings.';
      default:
        return code;
    }
  }

  /// Quick check: returns true if the device can perform biometric auth.
  Future<bool> isAvailable() async {
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Returns the list of enrolled biometric types.
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }
}
