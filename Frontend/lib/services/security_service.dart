import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:crypto/crypto.dart';

/// Manages the biometric domain state signature for the Triple-Lock protocol.
///
/// **iOS**: Uses `evaluatedPolicyDomainState` — a Uint8List that changes
///          whenever the enrolled face/finger database changes.
///
/// **Android**: Generates a SecretKey in the Android KeyStore that is
///              "invalidated" when new biometrics are enrolled. If the key
///              fails to initialise, we know the biometric set has changed.
///
/// The resulting signature hash is stored in FlutterSecureStorage. A mismatch
/// between the stored and current signatures triggers Tier 3B (Face Scan).
class SecurityService {
  static const _storage = FlutterSecureStorage();
  static const _kBioDomainStateKey = 'bio_domain_state_signature';
  static const _kBioChannel = MethodChannel('com.example.attendance_app/biometric');

  /// Returns the current biometric domain state as a hex-encoded SHA-256 hash.
  ///
  /// On iOS this is derived from the policy domain state.
  /// On Android we attempt to use the enrolled-biometrics list from local_auth
  /// as a heuristic proxy.
  static Future<String> _getCurrentSignature() async {
    try {
      if (Platform.isIOS) {
        return await _getIosSignature();
      } else if (Platform.isAndroid) {
        return await _getAndroidSignature();
      }
    } catch (e) {
      debugPrint('⚠️ [SecurityService] _getCurrentSignature error: $e');
    }
    // Fallback: use a stable placeholder so first-time users aren't forced
    // into a face scan on their very first attendance.
    return 'initial_signature';
  }

  /// iOS: Hash the evaluatedPolicyDomainState.
  static Future<String> _getIosSignature() async {
    try {
      final result = await _kBioChannel.invokeMethod<Uint8List>(
        'getBiometricDomainState',
      );
      if (result != null && result.isNotEmpty) {
        return sha256.convert(result).toString();
      }
    } catch (e) {
      debugPrint('⚠️ [SecurityService] iOS domain state error: $e');
    }
    // If the platform call fails, enumerate available biometrics as a proxy.
    return _enumerationBasedSignature();
  }

  /// Android: Use a KeyStore-bound approach via MethodChannel, with a
  /// fallback to biometric enumeration.
  static Future<String> _getAndroidSignature() async {
    try {
      // Try native KeyStore-based detection first
      final result = await _kBioChannel.invokeMethod<Map>('checkBiometricKeyValidity');
      if (result != null) {
        final bool keyValid = result['keyValid'] == true;
        if (!keyValid) {
          // Key was invalidated → biometrics changed
          // Return a unique string so the comparison will fail
          return 'android_key_invalidated_${DateTime.now().millisecondsSinceEpoch}';
        }
        return 'android_key_valid_${result['keyHash'] ?? 'stable'}';
      }
    } on MissingPluginException {
      // Native method not implemented yet — fall through to enumeration
      debugPrint('ℹ️ [SecurityService] Native key check not available, using enumeration fallback');
    } catch (e) {
      debugPrint('⚠️ [SecurityService] Android KeyStore check error: $e');
    }
    return _enumerationBasedSignature();
  }

  /// Fallback: Build a signature from the list of available biometric types.
  /// This changes when face/finger is added or removed.
  static Future<String> _enumerationBasedSignature() async {
    try {
      final auth = LocalAuthentication();
      final available = await auth.getAvailableBiometrics();
      // Sort for deterministic ordering
      final sorted = available.map((b) => b.toString()).toList()..sort();
      final payload = sorted.join('|');
      return sha256.convert(utf8.encode(payload)).toString();
    } catch (e) {
      debugPrint('⚠️ [SecurityService] Enumeration signature error: $e');
      return 'enumeration_error';
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Public API
  // ──────────────────────────────────────────────────────────────────────────

  /// Checks if the biometric domain state has changed since the last
  /// successful verification.
  ///
  /// Returns `true` if the signatures **match** (no change detected).
  /// Returns `false` if the signatures **differ** (change detected → Tier 3B).
  ///
  /// On first use (no stored signature), returns `true` and stores the
  /// current signature — the student is trusted on their first day.
  static Future<bool> checkBiometricSignature() async {
    final currentSig = await _getCurrentSignature();
    final storedSig = await _storage.read(key: _kBioDomainStateKey);

    debugPrint('🔐 [SecurityService] Current signature: $currentSig');
    debugPrint('🔐 [SecurityService] Stored  signature: ${storedSig ?? "(none)"}');

    if (storedSig == null) {
      // First run — store the initial signature and trust the user
      debugPrint('ℹ️ [SecurityService] First run — storing initial signature');
      await _storage.write(key: _kBioDomainStateKey, value: currentSig);
      return true; // signatures "match" (first time)
    }

    return currentSig == storedSig;
  }

  /// Updates the stored biometric domain state with the current one.
  ///
  /// Call this ONLY after a successful Face Scan in Scenario B. This is the
  /// "Security Persistence" step — the student won't be asked for a face
  /// scan again until their settings change.
  static Future<void> updateStoredSignature() async {
    final currentSig = await _getCurrentSignature();
    await _storage.write(key: _kBioDomainStateKey, value: currentSig);
    debugPrint('✅ [SecurityService] Stored signature updated → $currentSig');
  }

  /// Clears the stored signature (useful for testing / logout).
  static Future<void> clearStoredSignature() async {
    await _storage.delete(key: _kBioDomainStateKey);
    debugPrint('🗑️ [SecurityService] Stored signature cleared');
  }
}
