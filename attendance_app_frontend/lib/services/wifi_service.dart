import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:attendance_app/services/api_service.dart';

/// Result of a BSSID-based network validation check.
class BssidCheckResult {
  final bool isAuthorized;
  final String? bssid;     // The actual BSSID read from the device
  final String? errorMessage;

  const BssidCheckResult({
    required this.isAuthorized,
    this.bssid,
    this.errorMessage,
  });
}

class WifiService {
  final NetworkInfo _info = NetworkInfo();

  // ── Security constants ────────────────────────────────────────────────────
  /// Local fallback — used only when the backend is unreachable.
  /// Replace this with the REAL hardware MAC address of the classroom router.
  static const String _fallbackBssid = "00:0a:95:9d:68:16";

  /// Minimum acceptable RSSI (signal strength in dBm).
  static const int minRssi = -70;

  /// Maximum acceptable ping to the gateway (ms).
  static const int maxPingMs = 50;

  // ── Cached authorised BSSID from backend ──────────────────────────────────
  String? _cachedAuthorizedBssid;

  // ─────────────────────────────────────────────────────────────────────────

  /// Returns a normalised (lowercase, trimmed) BSSID string, or null.
  String? _normalise(String? raw) => raw?.trim().toLowerCase();

  /// ── Fetch the authorised BSSID from the backend ──────────────────────────
  ///
  /// Calls GET /api/attendance/authorized-bssid?classCode=<classCode>
  /// and caches the result. Falls back to [_fallbackBssid] on error.
  Future<String> getAuthorizedBssid({String? classCode}) async {
    if (_cachedAuthorizedBssid != null) return _cachedAuthorizedBssid!;

    try {
      final queryParam = classCode != null ? '?classCode=$classCode' : '';
      final response = await ApiService.get(
        '/attendance/authorized-bssid$queryParam',
      );

      if (response['success'] == true && response['authorizedBssid'] != null) {
        _cachedAuthorizedBssid = response['authorizedBssid'];
        debugPrint('📡 [WifiService] Authorized BSSID from backend: $_cachedAuthorizedBssid');
        return _cachedAuthorizedBssid!;
      }
    } catch (e) {
      debugPrint('⚠️ [WifiService] Could not fetch authorized BSSID: $e');
    }

    debugPrint('⚠️ [WifiService] Using fallback BSSID: $_fallbackBssid');
    return _fallbackBssid;
  }

  /// Clears the cached authorized BSSID (call when class changes).
  void clearCache() {
    _cachedAuthorizedBssid = null;
  }

  /// ── Primary security check (Tier 1: Network Gate) ────────────────────────
  ///
  /// Fetches the current BSSID from the device via [network_info_plus].
  /// Compares it with the authorised BSSID from the database.
  ///
  /// Returns a [BssidCheckResult]:
  ///   - [isAuthorized] == true → network gate PASSED
  ///   - [isAuthorized] == false → show SnackBar:
  ///       "You are not connected to the classroom Wi-Fi."
  Future<BssidCheckResult> validateBssid({String? classCode}) async {
    final bssid = await getBSSID();

    if (bssid == null || bssid.isEmpty) {
      return const BssidCheckResult(
        isAuthorized: false,
        errorMessage: 'Could not read network BSSID. '
            'Ensure Location permission is granted and Wi-Fi is on.',
      );
    }

    // Fetch the expected BSSID from the backend (or use cached/fallback)
    final authorizedBssid = await getAuthorizedBssid(classCode: classCode);

    final normActual = _normalise(bssid)!;
    final normExpected = _normalise(authorizedBssid)!;

    if (normActual != normExpected) {
      return BssidCheckResult(
        isAuthorized: false,
        bssid: bssid,
        errorMessage:
            'You are not connected to the classroom Wi-Fi.',
      );
    }

    return BssidCheckResult(isAuthorized: true, bssid: bssid);
  }

  // ─────────────────────────────────────────────────────────────────────────

  /// Reads the BSSID (hardware MAC of the current AP) from the device.
  ///
  /// Tries [network_info_plus] first; falls back to [wifi_iot] if the result
  /// looks like the Android privacy-placeholder address "02:00:00:00:00:00".
  Future<String?> getBSSID() async {
    String? bssid = await _info.getWifiBSSID();

    // Android returns "02:00:00:00:00:00" when Location permission is missing
    if (bssid == null || bssid == '02:00:00:00:00:00') {
      bssid = await WiFiForIoTPlugin.getBSSID();
    }

    return bssid?.trim();
  }

  /// Returns the human-readable SSID of the currently connected Wi-Fi network.
  Future<String?> getWifiName() async {
    final name = await _info.getWifiName();
    return name?.replaceAll('"', '');
  }

  /// Returns the current RSSI (signal strength in dBm).
  Future<int?> getSignalStrength() async {
    return WiFiForIoTPlugin.getCurrentSignalStrength();
  }

  /// Checks if Wi-Fi is physically enabled on the device.
  Future<bool> isWifiEnabled() async {
    return WiFiForIoTPlugin.isEnabled();
  }

  /// Derives the likely gateway IP by replacing the last octet with ".1".
  Future<String?> getGatewayIP() async {
    final ip = await _info.getWifiIP();
    if (ip != null) {
      final parts = ip.split('.');
      if (parts.length == 4) {
        parts[3] = '1';
        return parts.join('.');
      }
    }
    return null;
  }
}
