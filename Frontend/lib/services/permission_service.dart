import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

/// Handles runtime permission requests needed for BSSID / Wi-Fi info access.
///
/// Android: Requires ACCESS_FINE_LOCATION (and on Android 13+, NEARBY_WIFI_DEVICES).
/// iOS: Requires the com.apple.developer.networking.wifi-info entitlement set in
///      Xcode — permissions are granted automatically by the entitlement, so we
///      only need to ensure Location is available for completeness.
class PermissionService {
  /// Request all permissions required for BSSID reading.
  ///
  /// Returns `true` if all critical permissions are granted, `false` otherwise.
  static Future<bool> requestNetworkPermissions() async {
    if (Platform.isAndroid) {
      // On Android 9+ ACCESS_FINE_LOCATION is required to read BSSID.
      final locationStatus = await Permission.locationWhenInUse.request();

      if (locationStatus.isDenied || locationStatus.isPermanentlyDenied) {
        return false;
      }

      // Android 13+ also requires NEARBY_WIFI_DEVICES.
      // Requesting it here is a no-op on older Android versions, so safe to call.
      // We don't gate on this result — some devices don't expose this permission.
      await Permission.nearbyWifiDevices.request();

      return locationStatus.isGranted;
    }

    if (Platform.isIOS) {
      // iOS reads BSSID via the CNCopyCurrentNetworkInfo API.
      // The entitlement is compile-time, but requesting Location "When In Use"
      // improves reliability and is best practice.
      final locationStatus = await Permission.locationWhenInUse.request();
      return locationStatus.isGranted || locationStatus.isLimited;
    }

    // Other platforms (desktop/web) — not applicable, pass through.
    return true;
  }

  /// Check whether all required permissions are already granted without prompting.
  static Future<bool> areNetworkPermissionsGranted() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final status = await Permission.locationWhenInUse.status;
      return status.isGranted || status.isLimited;
    }
    return true;
  }

  /// Open the OS app settings so the user can manually grant denied permissions.
  static Future<void> openSettings() => openAppSettings();
}
