import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

class TelemetryService {
  static const String _kClientIdKey = 'telemetry_client_id';
  static const String _kLastPingDateKey = 'telemetry_last_ping_date';
  
  // Default Vercel production telemetry URL
  // The user can host this API on their Vercel project deployment
  static const String _kTelemetryUrl = 'https://gate-tracker-telemetry.vercel.app/api/ping';

  /// Generates a randomized secure client installation ID if not already existing
  static Future<String> _getOrCreateClientId(SharedPreferences prefs) async {
    String? clientId = prefs.getString(_kClientIdKey);
    if (clientId == null || clientId.isEmpty) {
      final random = Random.secure();
      final values = List<int>.generate(16, (i) => random.nextInt(256));
      clientId = values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      await prefs.setString(_kClientIdKey, clientId);
    }
    return clientId;
  }

  /// Resolve platform tag safely across web and native targets
  static String _getPlatformTag() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  /// Computes the daily SHA256 GDPR-compliant token
  static String _computeDailyToken(String clientId, String dateString) {
    final bytes = utf8.encode(clientId + dateString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Triggers a fire-and-forget daily active user telemetry ping
  static Future<void> triggerLaunchPing() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Get current date string (UTC)
      final String today = DateTime.now().toUtc().toIso8601String().split('T')[0];
      
      // 2. Cooldown check: ping at most once per UTC calendar day
      final String? lastPing = prefs.getString(_kLastPingDateKey);
      if (lastPing == today) {
        return; // Already registered ping for today, skip to save bandwidth/quota
      }

      // 3. Resolve client identifier and package version
      final String clientId = await _getOrCreateClientId(prefs);
      final String platform = _getPlatformTag();
      
      String version = '1.0.0';
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        version = packageInfo.version;
      } catch (_) {
        // Fallback for platform channels loading delays
      }

      // 4. Compute hashed daily token
      final String dailyToken = _computeDailyToken(clientId, today);

      // 5. Fire post ping
      final response = await http.post(
        Uri.parse(_kTelemetryUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'dailyToken': dailyToken,
          'version': version,
          'platform': platform,
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        // Record successful daily ping date in cache
        await prefs.setString(_kLastPingDateKey, today);
      }
    } catch (e) {
      // Telemetry is fail-silent to protect the app experience from connectivity glitches
      assert(() {
        debugPrint("Silent telemetry debug failure: $e");
        return true;
      }());
    }
  }
}
