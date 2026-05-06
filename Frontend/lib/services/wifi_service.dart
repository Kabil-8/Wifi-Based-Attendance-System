import 'dart:io';
import 'dart:async';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:dart_ping/dart_ping.dart';

class WifiService {
  final NetworkInfo _info = NetworkInfo();

  // Target BSSID - Replace with actual target BSSID or configure dynamically
  static const String targetBssid = "00:11:22:33:44:55"; 
  static const int minRssi = -70;
  static const int maxPingMs = 50;

  // change this to your real SSID
  static const collegeWifiName = "COLLEGE_WIFI";

  Future<bool> isConnectedToCollegeWifi() async {
    final name = await _info.getWifiName();

    if (name == null) return false;

    // some devices return with quotes
    final cleaned = name.replaceAll('"', '');

    return cleaned == collegeWifiName;
  }

  Future<String?> getWifiName() async {
    final name = await _info.getWifiName();
    return name?.replaceAll('"', '');
  }

  Future<String?> getBSSID() async {
    // Try network_info_plus first
    String? bssid = await _info.getWifiBSSID();
    if (bssid == null || bssid == "02:00:00:00:00:00") {
      // Fallback to wifi_iot
      bssid = await WiFiForIoTPlugin.getBSSID();
    }
    return bssid;
  }

  Future<int?> getSignalStrength() async {
    // wifi_iot provides RSSI
    return await WiFiForIoTPlugin.getCurrentSignalStrength();
  }

  Future<String?> getGatewayIP() async {
    // network_info_plus often returns IP but not gateway reliably on all platforms
    // wifi_iot might have better luck
    // Actually neither guarantees gateway IP easily without platform native code sometimes.
    // However, usually DHCP info is available.
    // Let's try to assume standard gateway if IP is known (e.g. ends in .1) or just use wifi_iot
    // But wifi_iot doesn't explicitly have getGatewayIP in all versions.
    // Let's check network_info_plus IP and assume gateway is x.x.x.1 ? 
    // Or use a clever trick?
    // Actually, on Android, `WiFiForIoTPlugin` might not expose gateway directly. 
    // `network_info_plus` returns `getWifiIP()`.
    
    // Let's try to ping the IP address obtained but replacing last octet with 1?
    // This is a heuristic.
    
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

  Future<int?> pingGateway(String gatewayIp) async {
    final ping = Ping(gatewayIp, count: 1);
    final Completer<int?> completer = Completer();
    
    ping.stream.listen((event) {
      if (event.response != null) {
        if (!completer.isCompleted) {
            completer.complete(event.response!.time?.inMilliseconds);
        }
      }
    }, onError: (e) {
       if (!completer.isCompleted) completer.complete(null);
    });

    // Timeout after 2 seconds
    return completer.future.timeout(const Duration(seconds: 2), onTimeout: () => null);
  }
}
